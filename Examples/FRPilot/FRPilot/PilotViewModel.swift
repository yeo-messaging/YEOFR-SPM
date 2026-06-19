//
//  PilotViewModel.swift
//  FRPilot
//

import AVFoundation
import Foundation
import Observation
import YEOFR

/// Forwards `FaceTrustService`'s two streams — live trust updates and enrolment
/// progress — into `@Observable` state the views render. The SDK owns the
/// engine, camera, fused-trust pipeline, identity gate, and persistence.
@MainActor
@Observable
final class PilotViewModel {

    private(set) var latestVerdict: TrustVerdict = .noFace
    private(set) var livenessText = "—"
    private(set) var depthText = "—"
    private(set) var enrolledName: String?
    /// `true` when the frame holds one well-framed face — when enrolment makes sense.
    private(set) var canEnrol = false

    private(set) var isEnrolling = false
    private(set) var enrolPrompt = "Hold steady…"
    private(set) var enrolPoseProgress: Double = 0
    private(set) var enrolTargetMatched = false

    /// Fused anti-spoof signal toggles, both default on. Flipping one re-applies
    /// the config to the running service (which resets trust state so the next
    /// frame re-evaluates cold). FR + the identity gate are unaffected — this only
    /// governs which signals contribute to `trusted`.
    private(set) var useLivenessSignal = true
    private(set) var useTrueDepthSignal = true

    var previewSession: AVCaptureSession { service.previewSession }
    let sdkVersion = YEOFRSDK.version

    /// Pilot code for a non-YEO bundle id — request your own from YEO.
    private static let pilotUnlockCode = "YOUR-PILOT-CODE"

    private let service: FaceTrustService
    /// Non-nil when encryption is available; used by the encrypted-persistence
    /// path and the encryption demo screen. nil only on the (near-impossible)
    /// Keychain failure handled in `init`.
    private let sdk: YEOFRSDK?
    private let cryptor: ChaChaPolyCryptor?
    private let cryptoStore: TrackerCryptoStore
    private var updatesLoop: Task<Void, Never>?
    private var enrolLoop: Task<Void, Never>?

    init() {
        let store = TrackerCryptoStore()
        cryptoStore = store
        do {
            // Build the SDK with the custom ChaChaPoly cryptor and let FaceTrustService
            // use a plaintext *scratch* file we wrap with encryption at rest.
            let cryptor = try ChaChaPolyCryptor.makeWithKeychainKey()
            let sdk = try YEOFRSDK(pilotUnlockCode: Self.pilotUnlockCode,
                                   encryption: .custom(cryptor))
            self.cryptor = cryptor
            self.sdk = sdk
            self.service = FaceTrustService(sdk: sdk, trackerURL: store.scratchURL)
        } catch {
            // Keychain unavailable (essentially never on-device): fall back to the
            // turnkey plaintext service so the pilot still runs; encrypted
            // persistence and the encryption demo are then disabled.
            print("[FRPilot] encryption unavailable, using plaintext service: \(error)")
            self.cryptor = nil
            self.sdk = nil
            self.service = FaceTrustService(pilotUnlockCode: Self.pilotUnlockCode)
        }
    }

    /// Start the service and fan its trust updates into observable state. Idempotent.
    func start() async {
        guard updatesLoop == nil else { return }
        // Decrypt the persisted enrolment into the plaintext scratch the SDK reads
        // during start(), so the identity gate arms from the encrypted blob. The
        // scratch is dropped immediately after (no plaintext tracker at rest).
        if let cryptor {
            do { try cryptoStore.restoreScratchForStart(using: cryptor) }
            catch { print("[FRPilot] could not restore encrypted tracker: \(error)") }
        }
        defer { cryptoStore.cleanupScratch() }
        do {
            try await service.start()
        } catch {
            print("[FRPilot] camera failed to start: \(error)")
            return
        }
        enrolledName = service.enrolledName

        updatesLoop = Task { [weak self] in
            guard let updates = self?.service.updates() else { return }
            for await update in updates {
                self?.apply(update)
            }
        }
    }

    func stop() {
        updatesLoop?.cancel(); updatesLoop = nil
        enrolLoop?.cancel(); enrolLoop = nil
        service.stop()
        latestVerdict = .noFace
        livenessText = "—"
        depthText = "—"
        canEnrol = false
        isEnrolling = false
        enrolPoseProgress = 0
        enrolTargetMatched = false
    }

    /// Toggle the liveness CNN signal. Re-applies the fused config live.
    func setLivenessSignal(_ on: Bool) {
        useLivenessSignal = on
        applyFusionConfig()
    }

    /// Toggle the TrueDepth 3D signal. Re-applies the fused config live.
    func setTrueDepthSignal(_ on: Bool) {
        useTrueDepthSignal = on
        applyFusionConfig()
    }

    private func applyFusionConfig() {
        let config = LivenessFusionConfig(useLivenessSDK: useLivenessSignal,
                                          useTrueDepthSDK: useTrueDepthSignal)
        Task { await service.setFusionConfig(config) }
    }

    private func apply(_ update: FaceTrustUpdate) {
        latestVerdict = Self.verdict(from: update)
        // A disabled signal reads "Off" rather than a stale/continuing value
        // (the SDK also reports nil for it, so this is belt-and-braces + clearer copy).
        livenessText = useLivenessSignal ? Self.describe(live: update.livenessGenuine) : "Off"
        depthText = useTrueDepthSignal ? Self.describe(threeD: update.depthIsThreeD) : "Off"
        canEnrol = !isEnrolling
            && update.faceCount == 1
            && (update.status == .trusted || update.status == .notTrusted)
    }

    /// How the most recent `beginEnrolment` should persist the tracker at rest.
    private var pendingEncrypted = false

    /// Enrol `name` from the live camera. The SDK drives the capture and re-arms
    /// the identity gate; on completion we persist the tracker at rest either as
    /// plaintext (`encrypted == false`) or ChaChaPoly-encrypted (`encrypted == true`).
    func beginEnrolment(name: String, encrypted: Bool) {
        guard !isEnrolling, canEnrol else { return }
        pendingEncrypted = encrypted
        isEnrolling = true
        enrolPrompt = "Hold steady…"
        enrolPoseProgress = 0
        enrolTargetMatched = false

        enrolLoop = Task { [weak self] in
            guard let steps = self?.service.enroll(name: name) else { return }
            for await step in steps {
                self?.applyEnrol(step)
            }
        }
    }

    private func applyEnrol(_ step: EnrollmentProgress) {
        switch step.phase {
        case .capturing:
            enrolPrompt = step.prompt
            enrolTargetMatched = step.isTargetMatched
            enrolPoseProgress = step.poseProgress
        case .completed:
            isEnrolling = false
            enrolPoseProgress = 1
            enrolledName = service.enrolledName
            // The service has just written the plaintext scratch; re-serialize it
            // (plaintext or encrypted) to tracker.blob so it survives relaunch.
            persistEnrolment(encrypted: pendingEncrypted)
        case .failed:
            isEnrolling = false
            enrolPrompt = step.prompt
        @unknown default:
            break
        }
    }

    /// Persist the freshly enrolled tracker at rest in the chosen mode.
    private func persistEnrolment(encrypted: Bool) {
        guard let sdk else { return }
        do { try cryptoStore.persist(from: sdk, encrypted: encrypted) }
        catch { print("[FRPilot] failed to persist tracker: \(error)") }
    }

    /// Forget the enrolment and delete the encrypted tracker at rest.
    func clearEnrolment() {
        service.clearEnrollment()
        cryptoStore.wipe()
        enrolledName = nil
        latestVerdict = .noFace
    }

    /// Snapshot for the encryption demo screen: the *actual* bytes persisted at
    /// rest (a serialized EncryptedBlob), the mode they were stored under, and a
    /// recoverability check — does the stored blob parse + decrypt back to a valid
    /// tracker envelope. nil when encryption is unavailable or nothing is persisted.
    ///
    /// We deliberately do NOT compare against `sdk.faceRecognitionTrackerData()`:
    /// the Luxand video tracker mutates its serialized state every processed
    /// frame, so the live bytes drift away from what was persisted at enrol and a
    /// byte-equality check would spuriously fail.
    func makeEncryptionDemo() -> EncryptionDemo? {
        guard let cryptor, let persisted = cryptoStore.persistedBlobData() else { return nil }
        do {
            let blob = try EncryptedBlob.parse(persisted)
            let recovered: Data
            switch blob.algorithmID {
            case EncryptedBlob.AlgorithmID.passthrough:
                recovered = blob.payload
            case cryptor.algorithmID:
                recovered = try cryptor.decrypt(blob)
            default:
                recovered = Data()
            }
            // A valid tracker envelope begins with the "YLXE" magic.
            let isValidTracker = recovered.starts(with: Data([0x59, 0x4C, 0x58, 0x45]))
            return EncryptionDemo(
                recoveredSize: recovered.count,
                persistedBlob: persisted,
                persistedAlgorithmID: blob.algorithmID,
                roundTripVerified: isValidTracker)
        } catch {
            print("[FRPilot] encryption demo failed: \(error)")
            return nil
        }
    }

    private static func verdict(from u: FaceTrustUpdate) -> TrustVerdict {
        switch u.status {
        case .noFace: return .noFace
        case .badFraming: return .badFraming
        case .notTrusted: return .notTrusted(similarity: u.bestSimilarity)
        case .trusted: return .trusted(name: u.matchedName, similarity: u.bestSimilarity)
        @unknown default: return .noFace
        }
    }

    private static func describe(live: Bool?) -> String {
        guard let live else { return "—" }
        return live ? "Live" : "Spoof"
    }

    private static func describe(threeD: Bool?) -> String {
        guard let threeD else { return "—" }
        return threeD ? "3D" : "Flat"
    }
}

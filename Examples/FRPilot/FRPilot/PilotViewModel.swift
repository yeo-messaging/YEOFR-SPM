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

    /// Fused anti-spoof signal toggles, both default on. Flipping one re-applies
    /// the config to the running service (which resets trust state so the next
    /// frame re-evaluates cold). FR + the identity gate are unaffected — this only
    /// governs which signals contribute to `trusted`.
    private(set) var useLivenessSignal = true
    private(set) var useTrueDepthSignal = true

    /// Placeholder so the unlicensed state doesn't hand out a fresh session per read.
    private let idleSession = AVCaptureSession()
    var previewSession: AVCaptureSession { service?.previewSession ?? idleSession }
    let sdkVersion = YEOFRSDK.version

    /// Non-nil when the SDK could not be constructed from a license; the UI
    /// shows this instead of the camera features.
    private(set) var licenseErrorText: String?

    // MARK: - Licensing
    //
    // The SDK accepts either credential; this app demonstrates both:
    //
    //   1. Signed license file (preferred) — a `FRPilot.yeolicense` bundled
    //      with the app. Bad/missing licenses surface as a catchable
    //      `YEOLicenseError`, shown on the Unlicensed screen.
    //   2. Pilot unlock code (legacy) — a time-limited code string. Used only
    //      if no license file is bundled AND the placeholder below was
    //      replaced. NOTE: an invalid or expired pilot code terminates the
    //      process inside the SDK (hard gate) — it cannot be caught here.
    //
    // Request either from christo@yeomessaging.com.

    /// Pilot code for a non-YEO bundle id — placeholder; replace with a real
    /// code only if you're not using a license file.
    private static let pilotUnlockCode = "YOUR-PILOT-CODE"

    /// Signed license file bundled with the app — request your own from YEO.
    /// A bundled license is absent, readable, or present-but-unreadable — three
    /// different situations that need three different remedies, so they are not
    /// collapsed into an optional.
    private enum BundledLicense {
        case absent
        case present(Data)
        case unreadable(Error)
    }

    private static func loadLicense() -> BundledLicense {
        guard let url = Bundle.main.url(forResource: "FRPilot", withExtension: "yeolicense") else {
            return .absent
        }
        do {
            return .present(try Data(contentsOf: url))
        } catch {
            return .unreadable(error)
        }
    }

    /// nil only when the license is missing/rejected (`licenseErrorText` set).
    private let service: FaceTrustService?
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
        let bundled = Self.loadLicense()
        if case .unreadable(let error) = bundled {
            // The file is in the bundle but cannot be read — telling the user to
            // add it would send them after a file that is already there.
            licenseErrorText = """
            FRPilot.yeolicense is bundled but could not be read: \(error.localizedDescription)
            Re-copy the file into the app bundle and rebuild.
            """
            cryptor = nil
            sdk = nil
            service = nil
            return
        }
        guard case .present(let license) = bundled else {
            // No license file bundled — fall back to the pilot code, if the
            // integrator supplied a real one.
            if Self.pilotUnlockCode != "YOUR-PILOT-CODE" {
                do {
                    let cryptor = try ChaChaPolyCryptor.makeWithKeychainKey()
                    let sdk = try YEOFRSDK(pilotUnlockCode: Self.pilotUnlockCode,
                                           encryption: .custom(cryptor))
                    self.cryptor = cryptor
                    self.sdk = sdk
                    self.service = FaceTrustService(sdk: sdk, trackerURL: store.scratchURL)
                } catch {
                    // Keychain unavailable: plaintext fallback, same as below.
                    print("[FRPilot] encryption unavailable, using plaintext service: \(error)")
                    self.cryptor = nil
                    self.sdk = nil
                    self.service = FaceTrustService(pilotUnlockCode: Self.pilotUnlockCode)
                }
                return
            }
            licenseErrorText = """
            This copy of FRPilot has no license.
            Contact christo@yeomessaging.com for licensing and \
            request your yeolicense file (or a pilot code), then \
            add it to the app bundle and rebuild.
            """
            cryptor = nil
            sdk = nil
            service = nil
            return
        }
        do {
            // Build the SDK with the custom ChaChaPoly cryptor and let FaceTrustService
            // use a plaintext *scratch* file we wrap with encryption at rest.
            let cryptor = try ChaChaPolyCryptor.makeWithKeychainKey()
            let sdk = try YEOFRSDK(license: license, encryption: .custom(cryptor))
            self.cryptor = cryptor
            self.sdk = sdk
            self.service = FaceTrustService(sdk: sdk, trackerURL: store.scratchURL)
        } catch let error as YEOLicenseError {
            licenseErrorText = """
            License rejected: \(error).
            Contact christo@yeomessaging.com for licensing.
            """
            cryptor = nil
            sdk = nil
            service = nil
        } catch {
            // Keychain unavailable (essentially never on-device): fall back to the
            // turnkey plaintext service so the pilot still runs; encrypted
            // persistence and the encryption demo are then disabled.
            print("[FRPilot] encryption unavailable, using plaintext service: \(error)")
            self.cryptor = nil
            self.sdk = nil
            if let sdk = try? YEOFRSDK(license: license) {
                self.service = FaceTrustService(sdk: sdk)
            } else {
                licenseErrorText = "License rejected on plaintext fallback"
                self.service = nil
            }
        }
    }

    /// Start the service and fan its trust updates into observable state. Idempotent.
    func start() async {
        guard let service, updatesLoop == nil else { return }
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
            guard let updates = self?.service?.updates() else { return }
            for await update in updates {
                self?.apply(update)
            }
        }
    }

    func stop() {
        updatesLoop?.cancel(); updatesLoop = nil
        enrolLoop?.cancel(); enrolLoop = nil
        service?.stop()
        latestVerdict = .noFace
        livenessText = "—"
        depthText = "—"
        canEnrol = false
        isEnrolling = false
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
        Task { await service?.setFusionConfig(config) }
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

        enrolLoop = Task { [weak self] in
            guard let steps = self?.service?.enroll(name: name) else { return }
            for await step in steps {
                self?.applyEnrol(step)
            }
        }
    }

    private func applyEnrol(_ step: EnrollmentProgress) {
        switch step.phase {
        case .capturing:
            enrolPrompt = step.prompt
        case .completed:
            isEnrolling = false
            enrolledName = service?.enrolledName
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
    func clearEnrolment() async {
        await service?.clearEnrollment()
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
    /// the recognition engine's video tracker mutates its serialized state every processed
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

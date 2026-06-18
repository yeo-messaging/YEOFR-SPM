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

    var previewSession: AVCaptureSession { service.previewSession }
    let sdkVersion = YEOFRSDK.version

    /// Pilot code for a non-YEO bundle id — request your own from YEO.
    private static let pilotUnlockCode = "YOUR-PILOT-CODE"

    private let service: FaceTrustService
    private var updatesLoop: Task<Void, Never>?
    private var enrolLoop: Task<Void, Never>?

    init() {
        service = FaceTrustService(pilotUnlockCode: Self.pilotUnlockCode)
    }

    /// Start the service and fan its trust updates into observable state. Idempotent.
    func start() async {
        guard updatesLoop == nil else { return }
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

    private func apply(_ update: FaceTrustUpdate) {
        latestVerdict = Self.verdict(from: update)
        livenessText = Self.describe(live: update.livenessGenuine)
        depthText = Self.describe(threeD: update.depthIsThreeD)
        canEnrol = !isEnrolling
            && update.faceCount == 1
            && (update.status == .trusted || update.status == .notTrusted)
    }

    /// Enrol `name` from the live camera. The SDK drives the capture, persists the
    /// gallery, and re-arms the identity gate; here we only mirror progress.
    func beginEnrolment(name: String) {
        guard !isEnrolling, canEnrol else { return }
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
        case .failed:
            isEnrolling = false
            enrolPrompt = step.prompt
        @unknown default:
            break
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

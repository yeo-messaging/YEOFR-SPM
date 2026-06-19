//
//  TrackerCryptoStore.swift
//  FRPilot
//
//  Persists the enrolled tracker as a self-describing `EncryptedBlob` envelope
//  (`tracker.blob`). The blob's algorithm-ID byte records how it was stored:
//
//    • 0x00 (passthrough) — "Enrol Face": the raw "YLXE" tracker in the clear.
//    • 0x80 (ChaChaPoly)  — "Enrol Face with Encryption": authenticated ciphertext.
//
//  Why a scratch file: `FaceTrustService` persists the tracker with the SDK's
//  raw (plaintext) APIs — `faceRecognitionTrackerData()` → write, and
//  `loadTracker(from: Data)` on launch. It never routes through the configured
//  cryptor. So FRPilot owns the at-rest envelope and wraps the service's plaintext
//  file as ephemeral scratch:
//
//    • launch  — parse `tracker.blob`, decrypt if needed, write the plaintext to
//                `scratchURL` BEFORE `service.start()` so the SDK's normal load
//                arms the identity gate. Then delete the scratch.
//    • enrol   — after the service writes scratch plaintext, re-serialize through
//                the chosen mode into `tracker.blob`, then delete the scratch.
//
//  Known limitation: a brief plaintext-on-disk window exists during launch-load
//  and immediately after an *encrypted* enrol (we delete it right away).
//  Eliminating it fully would require the SDK's `FaceTrustService` to persist
//  through its cryptor — out of scope for this FRPilot-only demo.
//

import Foundation
import YEOFR

struct TrackerCryptoStore {

    /// Canonical at-rest envelope (`EncryptedBlob.serialized()` bytes).
    let blobURL: URL
    /// Ephemeral plaintext the SDK's `FaceTrustService` loads/saves.
    let scratchURL: URL

    init() {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory,
                                in: .userDomainMask,
                                appropriateFor: nil,
                                create: true)) ?? fm.temporaryDirectory
        blobURL = base.appendingPathComponent("tracker.blob")
        scratchURL = base.appendingPathComponent("tracker.scratch")
    }

    var hasPersistedTracker: Bool {
        FileManager.default.fileExists(atPath: blobURL.path)
    }

    /// The exact bytes persisted at rest (a serialized `EncryptedBlob`), or nil
    /// when nothing is stored.
    func persistedBlobData() -> Data? {
        try? Data(contentsOf: blobURL)
    }

    /// Decrypt (if needed) the persisted blob into the plaintext scratch the SDK
    /// reads on `start()`. No-op when nothing is enrolled yet or the stored mode
    /// is unrecognised.
    func restoreScratchForStart(using cryptor: ChaChaPolyCryptor) throws {
        guard hasPersistedTracker else { return }
        let blob = try EncryptedBlob.parse(Data(contentsOf: blobURL))
        let plaintext: Data
        switch blob.algorithmID {
        case EncryptedBlob.AlgorithmID.passthrough:
            plaintext = blob.payload
        case cryptor.algorithmID:
            plaintext = try cryptor.decrypt(blob)
        default:
            return
        }
        try plaintext.write(to: scratchURL, options: .atomic)
    }

    /// Re-serialize the current tracker into `tracker.blob`. When `encrypted`, it
    /// goes through the SDK's `.custom` cryptor (algo 0x80); otherwise the raw
    /// bytes are wrapped in a passthrough envelope (algo 0x00). Drops the scratch.
    func persist(from sdk: YEOFRSDK, encrypted: Bool) throws {
        let blob: EncryptedBlob
        if encrypted {
            guard let encryptedBlob = try sdk.encryptedFaceRecognitionTrackerData() else { return }
            blob = encryptedBlob
        } else {
            let raw = sdk.faceRecognitionTrackerData()
            guard !raw.isEmpty else { return }
            blob = EncryptedBlob(algorithmID: EncryptedBlob.AlgorithmID.passthrough, payload: raw)
        }
        try blob.serialized().write(to: blobURL, options: .atomic)
        cleanupScratch()
    }

    /// Remove the plaintext scratch so the envelope is the only at-rest artifact.
    func cleanupScratch() {
        try? FileManager.default.removeItem(at: scratchURL)
    }

    /// Forget everything persisted (envelope + any scratch).
    func wipe() {
        try? FileManager.default.removeItem(at: blobURL)
        cleanupScratch()
    }
}

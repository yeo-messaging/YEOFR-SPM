//
//  EncryptionDemoView.swift
//  FRPilot
//
//  Shows the enrolled tracker serialized two ways via the YEOFR encryption API:
//  the built-in `.plaintext` mode (algorithm ID 0x00 — the "YLXE" envelope in
//  the clear) versus a custom ChaChaPoly `Cryptor` (algorithm ID 0x80 — opaque
//  authenticated ciphertext, which is what `tracker.enc` actually holds at rest).
//  PilotViewModel builds the snapshot through the SDK; this view only renders it.
//

import Foundation
import SwiftUI

/// View-facing snapshot of the tracker encryption demo (no SDK types here).
struct EncryptionDemo {
    /// Size of the recovered tracker envelope (the decrypted/parsed payload).
    let recoveredSize: Int
    /// The exact bytes stored at rest (a serialized EncryptedBlob).
    let persistedBlob: Data
    /// Algorithm-ID byte of the persisted blob (0x00 plaintext / 0x80 custom).
    let persistedAlgorithmID: UInt8
    let roundTripVerified: Bool
}

struct EncryptionDemoView: View {
    let viewModel: PilotViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var demo: EncryptionDemo?

    var body: some View {
        List {
            if let demo {
                overview(demo)
                persistedSection(demo)
                dangerZone
            } else {
                ContentUnavailableView(
                    "Encryption demo unavailable",
                    systemImage: "lock.slash",
                    description: Text("Enrol a face first. Encryption is disabled only if the Keychain key could not be created."))
            }
        }
        .navigationTitle("Tracker Encryption")
        .navigationBarTitleDisplayMode(.inline)
        .task { demo = viewModel.makeEncryptionDemo() }
    }

    private func overview(_ d: EncryptionDemo) -> some View {
        Section("Tracker") {
            LabeledContent("Tracker size", value: "\(d.recoveredSize) bytes")
            LabeledContent("At rest", value: atRestText(d.persistedAlgorithmID))
            LabeledContent("Round-trip") {
                Label(d.roundTripVerified ? "verified" : "FAILED",
                      systemImage: d.roundTripVerified ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(d.roundTripVerified ? .green : .red)
            }
        }
    }

    /// The single section matching what's actually stored at rest — the real
    /// `tracker.blob` bytes, not a re-serialization.
    private func persistedSection(_ d: EncryptionDemo) -> some View {
        let isPlaintext = d.persistedAlgorithmID == 0x00
        return blobSection(
            isPlaintext
                ? "Plaintext — .plaintext (algo 0x00)"
                : "Custom — ChaChaPoly (algo 0x\(hex(d.persistedAlgorithmID)))",
            bytes: d.persistedBlob,
            note: isPlaintext
                ? "The bytes actually stored in tracker.blob — no encryption. The \"YLXE\" envelope is in the clear; see the ASCII."
                : "The bytes actually stored in tracker.blob — ChaChaPoly ciphertext (nonce‖ciphertext‖tag). Opaque; the ASCII is garbage.")
    }

    private func blobSection(_ title: String, bytes: Data, note: String) -> some View {
        Section(title) {
            Text(note)
                .font(.caption)
                .foregroundStyle(.secondary)
            LabeledContent("Serialized size", value: "\(bytes.count) bytes")
            VStack(alignment: .leading, spacing: 6) {
                Text("First \(min(32, bytes.count)) bytes")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(hexPreview(bytes, limit: 32))
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                Text("ASCII  \(asciiPreview(bytes, limit: 32))")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var dangerZone: some View {
        Section {
            Button(role: .destructive) {
                viewModel.clearEnrolment()
                dismiss()
            } label: {
                Label("Forget enrolment & delete tracker.blob", systemImage: "trash")
            }
        }
    }

    private func atRestText(_ algorithmID: UInt8) -> String {
        switch algorithmID {
        case 0x00: return "plaintext (0x00)"
        case 0x80: return "encrypted (0x80)"
        default: return "algo 0x\(hex(algorithmID))"
        }
    }

    // MARK: Byte formatting

    private func hex(_ byte: UInt8) -> String { String(format: "%02X", Int(byte)) }

    private func hexPreview(_ data: Data, limit: Int) -> String {
        data.prefix(limit).map { hex($0) }.joined(separator: " ")
    }

    private func asciiPreview(_ data: Data, limit: Int) -> String {
        String(data.prefix(limit).map { (32...126).contains($0) ? Character(UnicodeScalar($0)) : "." })
    }
}

//
//  EnrolView.swift
//  FRPilot
//

import SwiftUI

struct EnrolView: View {
    let viewModel: PilotViewModel
    let name: String
    /// Persist the enrolled tracker ChaChaPoly-encrypted at rest when true.
    var encrypted: Bool = false
    @Environment(\.dismiss) private var dismiss

    /// Set on tap so the completion `task` only dismisses after a started walk.
    @State private var started = false

    var body: some View {
        ZStack {
            CameraPreview(session: viewModel.previewSession)
                .ignoresSafeArea()

            VStack {
                Spacer()
                if viewModel.isEnrolling {
                    enrolmentProgress
                } else {
                    idlePrompt
                }
            }
            .padding()
        }
        .navigationTitle("Enrol")
        .navigationBarTitleDisplayMode(.inline)
        // Pop back once the capture finishes. `task(id:)` re-runs on change.
        .task(id: viewModel.isEnrolling) {
            if started && !viewModel.isEnrolling { dismiss() }
        }
    }

    private var idlePrompt: some View {
        VStack(spacing: 16) {
            Text(prompt)
                .font(.headline)
                .padding(12)
                .background(.black.opacity(0.6), in: Capsule())
                .foregroundStyle(.white)

            Button {
                started = true
                viewModel.beginEnrolment(name: name, encrypted: encrypted)
            } label: {
                Label(encrypted ? "Enrol \(name) (Encrypted)" : "Enrol \(name)",
                      systemImage: encrypted ? "lock.shield" : "person.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(encrypted ? .indigo : .accentColor)
            .disabled(!viewModel.canEnrol)
        }
    }

    private var prompt: String {
        if viewModel.canEnrol { return "Ready — tap Enrol, then hold still facing the camera" }
        switch viewModel.latestVerdict {
        case .noFace: return "Show your face to the camera"
        case .badFraming: return "Center your face in the frame"
        default: return "Hold steady…"
        }
    }

    private var enrolmentProgress: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text(viewModel.enrolPrompt)
                    .font(.headline)
                if viewModel.enrolTargetMatched {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            ProgressView(value: viewModel.enrolPoseProgress)
                .tint(.green)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.white)
    }
}

//
//  RecogniseView.swift
//  FRPilot
//

import SwiftUI

struct RecogniseView: View {
    let viewModel: PilotViewModel

    var body: some View {
        ZStack {
            CameraPreview(session: viewModel.previewSession)
                .ignoresSafeArea()

            VStack {
                controls
                    .padding(.horizontal, 28)
                    .padding(.top, 12)
                Spacer()
                badge
                    .padding(.bottom, 40)
            }
        }
        .navigationTitle("Recognition")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Live anti-spoof signal toggles. Custom `Binding`s call the view model's
    /// setters (no `onChange`); flipping one re-applies the fused config.
    private var controls: some View {
        VStack(spacing: 8) {
            Toggle("Liveness signal", isOn: Binding(
                get: { viewModel.useLivenessSignal },
                set: { viewModel.setLivenessSignal($0) }))
            Toggle("TrueDepth signal", isOn: Binding(
                get: { viewModel.useTrueDepthSignal },
                set: { viewModel.setTrueDepthSignal($0) }))
        }
        .toggleStyle(.switch)
        .tint(.green)
        .font(.callout)
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
    }

    private var badge: some View {
        VStack(spacing: 8) {
            Text(headline)
                .font(.largeTitle.bold())
                .foregroundStyle(color)

            HStack(spacing: 16) {
                signal("Match", similarityText)
                signal("Liveness", viewModel.livenessText)
                signal("Depth", viewModel.depthText)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
    }

    private func signal(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.white)
        }
    }

    private var headline: String {
        switch viewModel.latestVerdict {
        case .trusted(let name, _): return name.map { "TRUSTED — \($0)" } ?? "TRUSTED"
        case .notTrusted: return "NOT TRUSTED"
        case .badFraming: return "ADJUST FRAMING"
        case .noFace: return "NO FACE"
        }
    }

    private var color: Color {
        if case .trusted = viewModel.latestVerdict { return .green }
        return .red
    }

    private var similarityText: String {
        switch viewModel.latestVerdict {
        case .trusted(_, let s), .notTrusted(let s):
            return s.map { String(format: "%.2f", $0) } ?? "—"
        case .badFraming, .noFace:
            return "—"
        }
    }
}

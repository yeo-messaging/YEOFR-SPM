//
//  ContentView.swift
//  FRPilot
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = PilotViewModel()
    @State private var name = ""

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "faceid")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)

                Text("YEOFR Pilot")
                    .font(.title2.bold())

                enrolmentStatus

                TextField("Name (e.g. Alice)", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)

                NavigationLink {
                    EnrolView(viewModel: viewModel, name: trimmedName)
                } label: {
                    Label("Enrol Face", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(trimmedName.isEmpty)

                NavigationLink {
                    RecogniseView(viewModel: viewModel)
                } label: {
                    Label("Live Recognition", systemImage: "viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                // Recognition needs a gallery — enrol first.
                .disabled(viewModel.enrolledName == nil)

                Spacer()

                Text("YEOFR SDK \(viewModel.sdkVersion)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("FRPilot")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    private var enrolmentStatus: some View {
        HStack(spacing: 6) {
            Image(systemName: viewModel.enrolledName == nil
                  ? "circle" : "checkmark.circle.fill")
                .foregroundStyle(viewModel.enrolledName == nil ? Color.secondary : Color.green)
            Text(viewModel.enrolledName.map { "Enrolled: \($0)" } ?? "Not enrolled")
                .foregroundStyle(.secondary)
        }
        .font(.callout)
    }
}

#Preview {
    ContentView()
}

import SwiftUI

struct ContentView: View {
    var viewModel: ACViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 16) {
            if !viewModel.isConfigured {
                notConfiguredView
            } else {
                controlsView
            }
        }
        .padding()
        .task {
            guard viewModel.isConfigured else { return }
            viewModel.startPolling()
        }
    }

    private var notConfiguredView: some View {
        VStack(spacing: 12) {
            Image(systemName: "gear")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("AC not configured")
                .font(.headline)
            Text("Enter your Home Assistant details to get started.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                openWindow(id: "settings")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var controlsView: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: viewModel.statusIcon)
                    .foregroundStyle(viewModel.statusColor)
                Text("Mitsubishi AC")
                    .font(.headline)
                Spacer()
                Button(action: { openWindow(id: "settings") }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
            }

            Divider()

            // Room temperature
            if let currentTemp = viewModel.currentTemp {
                Text("Room: \(currentTemp, specifier: "%.1f")°C")
                    .font(.system(.title2, design: .rounded))
            }

            // Target temperature
            TemperatureControl(viewModel: viewModel)

            // Mode selector
            ModeSelector(viewModel: viewModel)

            // Status
            if let action = viewModel.hvacAction, action != "off" {
                HStack {
                    Image(systemName: viewModel.statusIcon)
                    Text(action.capitalized)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // Power toggle
            Button(viewModel.hvacMode == "off" ? "Turn On" : "Turn Off") {
                Task { await viewModel.togglePower() }
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .tint(viewModel.hvacMode == "off" ? .green : .red)

            // Error
            if let error = viewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            // Quit
            Button("Quit AC") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

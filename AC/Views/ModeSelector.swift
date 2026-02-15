import SwiftUI

struct ModeSelector: View {
    var viewModel: ACViewModel

    private var activeModes: [String] {
        viewModel.hvacModes.filter { $0 != "off" }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mode")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(activeModes, id: \.self) { mode in
                    Button(action: {
                        Task { await viewModel.setMode(mode) }
                    }) {
                        Label(displayName(for: mode), systemImage: icon(for: mode))
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(viewModel.hvacMode == mode ? tint(for: mode) : .gray.opacity(0.3))
                    .controlSize(.small)
                }
            }
        }
    }

    private func displayName(for mode: String) -> String {
        switch mode {
        case "auto": "Auto"
        case "heat": "Heat"
        case "cool": "Cool"
        case "dry": "Dry"
        case "fan_only": "Fan"
        default: mode.capitalized
        }
    }

    private func icon(for mode: String) -> String {
        switch mode {
        case "auto": "arrow.trianglehead.2.clockwise"
        case "heat": "flame"
        case "cool": "snowflake"
        case "dry": "drop.degreesign"
        case "fan_only": "fan"
        default: "questionmark"
        }
    }

    private func tint(for mode: String) -> Color {
        switch mode {
        case "heat": .orange
        case "cool": .blue
        case "dry": .teal
        case "fan_only": .mint
        case "auto": .purple
        default: .gray
        }
    }
}

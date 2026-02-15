import SwiftUI

struct TemperatureControl: View {
    var viewModel: ACViewModel

    var body: some View {
        HStack(spacing: 16) {
            Button(action: { Task { await viewModel.decreaseTemp() } }) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.targetTemp <= viewModel.minTemp)

            Text("\(viewModel.targetTemp, specifier: "%.1f")°C")
                .font(.system(.title, design: .rounded))
                .monospacedDigit()

            Button(action: { Task { await viewModel.increaseTemp() } }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.targetTemp >= viewModel.maxTemp)
        }
        .padding(.vertical, 4)
    }
}

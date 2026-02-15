import SwiftUI

@main
struct ACApp: App {
    @State private var viewModel = ACViewModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView(viewModel: viewModel)
                .frame(width: 280)
        } label: {
            if viewModel.hvacMode == "off" {
                Image(systemName: "circle.fill")
                    .foregroundStyle(.red)
            } else {
                Text("\(viewModel.targetTemp, specifier: "%.0f")°")
            }
        }
        .menuBarExtraStyle(.window)

        Window("AC Settings", id: "settings") {
            SettingsView(viewModel: viewModel)
                .frame(width: 350)
                .fixedSize()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

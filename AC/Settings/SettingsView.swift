import SwiftUI

struct SettingsView: View {
    var viewModel: ACViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var url: String = ""
    @State private var token: String = ""
    @State private var entity: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AC Settings")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 4) {
                Text("Home Assistant URL")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("http://10.0.0.5:8123", text: $url)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Access Token")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SecureField("Long-lived access token", text: $token)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Entity ID")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("climate.ma_touch_...", text: $entity)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Save") {
                    viewModel.saveSettings(url: url, token: token, entity: entity)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(url.isEmpty || token.isEmpty || entity.isEmpty)
            }
        }
        .padding(24)
        .onAppear {
            url = viewModel.haURL
            token = viewModel.haToken
            entity = viewModel.entityId
        }
    }
}

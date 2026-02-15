import SwiftUI

@Observable
class ACViewModel {
    // MARK: - State
    var currentTemp: Double?
    var targetTemp: Double = 24.0
    var hvacMode: String = "off"
    var hvacAction: String?
    var hvacModes: [String] = ["off", "auto", "heat", "cool", "dry", "fan_only"]
    var minTemp: Double = 16.0
    var maxTemp: Double = 31.0
    var error: String?

    // MARK: - Settings
    var haURL: String
    var haToken: String
    var entityId: String

    var isConfigured: Bool {
        !haURL.isEmpty && !haToken.isEmpty && !entityId.isEmpty
    }

    // MARK: - Computed UI
    var menuBarIcon: String {
        switch hvacMode {
        case "cool": "snowflake"
        case "heat": "flame"
        case "dry": "drop.degreesign"
        case "fan_only": "fan"
        case "auto": "arrow.trianglehead.2.clockwise"
        default: "power"
        }
    }

    var statusIcon: String {
        switch hvacAction {
        case "cooling": "snowflake"
        case "heating": "flame"
        case "drying": "drop.degreesign"
        case "fan": "fan"
        case "idle": "pause.circle"
        default: "power"
        }
    }

    var statusColor: Color {
        switch hvacAction {
        case "cooling": .blue
        case "heating": .orange
        default: .secondary
        }
    }

    // MARK: - Private
    private var pollingTask: Task<Void, Never>?

    private var api: HomeAssistantAPI? {
        guard isConfigured else { return nil }
        return HomeAssistantAPI(baseURL: haURL, token: haToken, entityId: entityId)
    }

    // MARK: - Init
    init() {
        let settings = SettingsStore.load()
        self.haURL = settings.haURL
        self.haToken = settings.haToken
        self.entityId = settings.entityId
        Log.info("ACViewModel init — configured: \(!settings.haURL.isEmpty && !settings.haToken.isEmpty && !settings.entityId.isEmpty)")
    }

    // MARK: - Settings
    func saveSettings(url: String, token: String, entity: String) {
        haURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        haToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        entityId = entity.trimmingCharacters(in: .whitespacesAndNewlines)

        SettingsStore.save(AppSettings(haURL: haURL, haToken: haToken, entityId: entityId))
        startPolling()
    }

    // MARK: - Polling
    func startPolling() {
        pollingTask?.cancel()
        Log.info("Starting polling (10s interval)")
        pollingTask = Task {
            while !Task.isCancelled {
                await fetchState()
                try? await Task.sleep(for: .seconds(10))
            }
        }
    }

    func stopPolling() {
        Log.info("Stopping polling")
        pollingTask?.cancel()
        pollingTask = nil
    }

    // MARK: - API Actions
    func fetchState() async {
        guard let api else { return }
        do {
            let state = try await api.getState()
            hvacMode = state.state
            currentTemp = state.attributes.currentTemperature
            targetTemp = state.attributes.temperature ?? targetTemp
            hvacAction = state.attributes.hvacAction
            if let modes = state.attributes.hvacModes {
                hvacModes = modes
            }
            if let min = state.attributes.minTemp { minTemp = min }
            if let max = state.attributes.maxTemp { maxTemp = max }
            error = nil
        } catch {
            self.error = "\(error)"
        }
    }

    func setMode(_ mode: String) async {
        guard let api else { return }
        do {
            try await api.setHVACMode(mode)
            hvacMode = mode
            error = nil
        } catch {
            self.error = "\(error)"
        }
    }

    func setTemperature(_ temp: Double) async {
        guard let api else { return }
        let clamped = min(max(temp, minTemp), maxTemp)
        do {
            try await api.setTemperature(clamped)
            targetTemp = clamped
            error = nil
        } catch {
            self.error = "\(error)"
        }
    }

    func togglePower() async {
        if hvacMode == "off" {
            await setMode("auto")
        } else {
            await setMode("off")
        }
    }

    func increaseTemp() async {
        await setTemperature(targetTemp + 0.5)
    }

    func decreaseTemp() async {
        await setTemperature(targetTemp - 0.5)
    }
}

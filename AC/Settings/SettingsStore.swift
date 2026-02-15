import Foundation

struct AppSettings: Codable {
    var haURL: String = ""
    var haToken: String = ""
    var entityId: String = ""
}

enum SettingsStore {
    private static let defaults = UserDefaults.standard

    static func load() -> AppSettings {
        let settings = AppSettings(
            haURL: defaults.string(forKey: "ac_haURL") ?? "",
            haToken: defaults.string(forKey: "ac_haToken") ?? "",
            entityId: defaults.string(forKey: "ac_entityId") ?? ""
        )
        Log.info("Loaded settings — configured: \(!settings.haURL.isEmpty && !settings.haToken.isEmpty && !settings.entityId.isEmpty)")
        return settings
    }

    static func save(_ settings: AppSettings) {
        defaults.set(settings.haURL, forKey: "ac_haURL")
        defaults.set(settings.haToken, forKey: "ac_haToken")
        defaults.set(settings.entityId, forKey: "ac_entityId")
        defaults.synchronize()
        Log.info("Settings saved — URL: \(settings.haURL), entity: \(settings.entityId)")
    }
}

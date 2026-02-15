import Foundation

struct ClimateState: Codable, Sendable {
    let entityId: String
    let state: String
    let attributes: Attributes

    enum CodingKeys: String, CodingKey {
        case entityId = "entity_id"
        case state
        case attributes
    }

    struct Attributes: Codable, Sendable {
        let currentTemperature: Double?
        let temperature: Double?
        let hvacAction: String?
        let hvacModes: [String]?
        let minTemp: Double?
        let maxTemp: Double?

        enum CodingKeys: String, CodingKey {
            case currentTemperature = "current_temperature"
            case temperature
            case hvacAction = "hvac_action"
            case hvacModes = "hvac_modes"
            case minTemp = "min_temp"
            case maxTemp = "max_temp"
        }
    }
}

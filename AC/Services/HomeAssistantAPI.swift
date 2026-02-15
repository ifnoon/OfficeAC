import Foundation

struct HomeAssistantAPI: Sendable {
    let baseURL: String
    let token: String
    let entityId: String

    func getState() async throws -> ClimateState {
        let url = try makeURL("/api/states/\(entityId)")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(response)
        return try JSONDecoder().decode(ClimateState.self, from: data)
    }

    func setHVACMode(_ mode: String) async throws {
        let url = try makeURL("/api/services/climate/set_hvac_mode")
        var request = makePostRequest(url: url)
        request.httpBody = try JSONEncoder().encode([
            "entity_id": entityId,
            "hvac_mode": mode
        ])
        let (_, response) = try await URLSession.shared.data(for: request)
        try checkResponse(response)
    }

    func setTemperature(_ temperature: Double) async throws {
        let url = try makeURL("/api/services/climate/set_temperature")
        var request = makePostRequest(url: url)
        let body: [String: Any] = [
            "entity_id": entityId,
            "temperature": temperature
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        try checkResponse(response)
    }

    private func makeURL(_ path: String) throws -> URL {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.detail("Invalid URL: \(baseURL)\(path)")
        }
        return url
    }

    private func makePostRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func checkResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.detail("Not an HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.detail("HTTP \(http.statusCode) from \(http.url?.absoluteString ?? "?")")
        }
    }
}

enum APIError: LocalizedError {
    case detail(String)

    var errorDescription: String? {
        switch self {
        case .detail(let msg): msg
        }
    }
}

import Cocoa
import Foundation

// MARK: - Config
struct Config: Codable {
    let haURL: String
    let haToken: String
    let entity: String
}

func loadConfig() -> Config {
    let configPath = (CommandLine.arguments[0] as NSString).deletingLastPathComponent + "/config.json"
    if let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
       let config = try? JSONDecoder().decode(Config.self, from: data) {
        return config
    }
    return Config(haURL: "http://10.0.0.5:8123", haToken: "", entity: "")
}

// MARK: - Parse args
var port = 0
var pluginUUID = ""
var registerEvent = ""

let args = CommandLine.arguments
var i = 1
while i < args.count - 1 {
    switch args[i] {
    case "-port": port = Int(args[i+1]) ?? 0
    case "-pluginUUID": pluginUUID = args[i+1]
    case "-registerEvent": registerEvent = args[i+1]
    default: break
    }
    i += 2
}

let config = loadConfig()

// MARK: - State
var toggleContexts: [String] = []
var tempUpContexts: [String] = []
var tempDownContexts: [String] = []
var currentMode = "off"
var currentTemp = 24.0
var wsTask: URLSessionWebSocketTask?
var fastPollTimer: Timer?
var fastPollCount = 0

// MARK: - Image generation
func renderButton(text: String, isOn: Bool) -> String? {
    let size = 144
    let s = CGFloat(size)

    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()

    // Background color
    let bg: NSColor = isOn
        ? NSColor(calibratedRed: 0.15, green: 0.55, blue: 0.95, alpha: 1.0)
        : NSColor(calibratedRed: 0.35, green: 0.35, blue: 0.38, alpha: 1.0)

    bg.setFill()
    NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: s, height: s),
                 xRadius: s * 0.15, yRadius: s * 0.15).fill()

    // Text
    let fontSize: CGFloat = text.count <= 3 ? s * 0.45 : s * 0.35
    let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white
    ]
    let str = NSAttributedString(string: text, attributes: attrs)
    let strSize = str.size()
    str.draw(at: NSPoint(x: (s - strSize.width) / 2, y: (s - strSize.height) / 2))

    img.unlockFocus()

    // Convert to PNG base64
    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { return nil }

    return "data:image/png;base64," + png.base64EncodedString()
}

// MARK: - WebSocket helpers
func send(_ dict: [String: Any]) {
    guard let data = try? JSONSerialization.data(withJSONObject: dict),
          let str = String(data: data, encoding: .utf8) else { return }
    wsTask?.send(.string(str)) { _ in }
}

func setImage(_ context: String, _ base64: String) {
    send([
        "event": "setImage",
        "context": context,
        "payload": ["image": base64, "target": 0]
    ])
}

func setTitle(_ context: String, _ title: String) {
    send([
        "event": "setTitle",
        "context": context,
        "payload": ["title": "", "target": 0]
    ])
}

func updateAllButtons() {
    let isOn = currentMode != "off"
    let tempText = isOn ? String(format: "%.1f°", currentTemp) : "OFF"

    if let img = renderButton(text: tempText, isOn: isOn) {
        toggleContexts.forEach { setImage($0, img) }
    }
    if let img = renderButton(text: "+", isOn: isOn) {
        tempUpContexts.forEach { setImage($0, img) }
    }
    if let img = renderButton(text: "−", isOn: isOn) {
        tempDownContexts.forEach { setImage($0, img) }
    }
    // Clear default titles
    (toggleContexts + tempUpContexts + tempDownContexts).forEach { setTitle($0, "") }
}

// MARK: - HA API
func haRequest(_ method: String, path: String, body: [String: Any]? = nil, completion: @escaping (Data?) -> Void) {
    guard let url = URL(string: "\(config.haURL)\(path)") else {
        completion(nil)
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("Bearer \(config.haToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let body = body {
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    }
    URLSession.shared.dataTask(with: request) { data, _, _ in
        completion(data)
    }.resume()
}

func pollHA() {
    haRequest("GET", path: "/api/states/\(config.entity)") { data in
        guard let data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let state = json["state"] as? String,
              let attrs = json["attributes"] as? [String: Any] else {
            if let img = renderButton(text: "ERR", isOn: false) {
                toggleContexts.forEach { setImage($0, img) }
            }
            return
        }
        currentMode = state
        currentTemp = attrs["temperature"] as? Double ?? currentTemp
        updateAllButtons()
    }
}

func startFastPolling() {
    fastPollTimer?.invalidate()
    fastPollCount = 0
    fastPollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
        fastPollCount += 1
        pollHA()
        if fastPollCount >= 10 {
            timer.invalidate()
            fastPollTimer = nil
        }
    }
}

func toggleAC() {
    let newMode = currentMode == "off" ? "cool" : "off"
    haRequest("POST", path: "/api/services/climate/set_hvac_mode",
              body: ["entity_id": config.entity, "hvac_mode": newMode]) { _ in
        DispatchQueue.main.async { startFastPolling() }
    }
}

func adjustTemp(_ delta: Double) {
    let newTemp = min(max(currentTemp + delta, 16), 31)
    haRequest("POST", path: "/api/services/climate/set_temperature",
              body: ["entity_id": config.entity, "temperature": newTemp]) { _ in
        currentTemp = newTemp
        updateAllButtons()
        DispatchQueue.main.async { startFastPolling() }
    }
}

// MARK: - WebSocket message handler
func handleMessage(_ text: String) {
    guard let data = text.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let event = json["event"] as? String else { return }

    let context = json["context"] as? String ?? ""
    let action = json["action"] as? String ?? ""

    switch event {
    case "willAppear":
        if action.contains("toggle") && !toggleContexts.contains(context) {
            toggleContexts.append(context)
        } else if action.contains("tempup") && !tempUpContexts.contains(context) {
            tempUpContexts.append(context)
        } else if action.contains("tempdown") && !tempDownContexts.contains(context) {
            tempDownContexts.append(context)
        }
        pollHA()

    case "willDisappear":
        toggleContexts.removeAll { $0 == context }
        tempUpContexts.removeAll { $0 == context }
        tempDownContexts.removeAll { $0 == context }

    case "keyDown":
        if action.contains("toggle") { toggleAC() }
        else if action.contains("tempup") { adjustTemp(0.5) }
        else if action.contains("tempdown") { adjustTemp(-0.5) }

    default: break
    }
}

func listen() {
    wsTask?.receive { result in
        switch result {
        case .success(.string(let text)):
            handleMessage(text)
        default: break
        }
        listen()
    }
}

// MARK: - Connect
let url = URL(string: "ws://127.0.0.1:\(port)")!
let session = URLSession(configuration: .default)
wsTask = session.webSocketTask(with: url)
wsTask?.resume()

send(["event": registerEvent, "uuid": pluginUUID])
listen()

Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in pollHA() }

RunLoop.main.run()

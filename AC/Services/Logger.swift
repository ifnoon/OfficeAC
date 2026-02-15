import Foundation

enum Log {
    static let logURL: URL = {
        let url = URL(fileURLWithPath: "/tmp/ac.log")
        // Clear on launch
        try? FileManager.default.removeItem(at: url)
        return url
    }()

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()

    static func info(_ message: String) { write("INFO", message) }
    static func error(_ message: String) { write("ERROR", message) }
    static func debug(_ message: String) { write("DEBUG", message) }

    private static func write(_ level: String, _ message: String) {
        let timestamp = formatter.string(from: Date())
        let line = "[\(timestamp)] [\(level)] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: logURL.path) {
            if let handle = try? FileHandle(forWritingTo: logURL) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        } else {
            FileManager.default.createFile(atPath: logURL.path, contents: data)
        }
    }
}

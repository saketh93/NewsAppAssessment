import Foundation
import OSLog

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.newsappassessment"
    private static let networkLogger = Logger(subsystem: subsystem, category: "Network")
    private static let uiLogger = Logger(subsystem: subsystem, category: "UI")
    private static let errorLogger = Logger(subsystem: subsystem, category: "Error")
    private static let warningLogger = Logger(subsystem: subsystem, category: "Warning")
    private static let generalLogger = Logger(subsystem: subsystem, category: "General")
    private static let analyticsLogger = Logger(subsystem: subsystem, category: "Analytics")

    static func network(_ message: String) {
        networkLogger.debug("[Network] \(redact(message), privacy: .public)")
    }

    static func info(_ message: String) {
        generalLogger.info("[Info] \(redact(message), privacy: .public)")
    }

    static func ui(_ message: String) {
        uiLogger.debug("[UI] \(redact(message), privacy: .public)")
    }

    static func warning(_ message: String) {
        warningLogger.warning("[Warning] \(redact(message), privacy: .public)")
    }

    static func error(_ message: String) {
        errorLogger.error("[Error] \(redact(message), privacy: .public)")
    }

    static func analytics(_ message: String) {
        analyticsLogger.info("[Analytics] \(message, privacy: .public)")
    }

    static func redact(_ string: String) -> String {
        let pattern = "(apikey=)[^&\\s]+"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return string
        }
        let range = NSRange(string.startIndex..., in: string)
        return regex.stringByReplacingMatches(
            in: string,
            options: [],
            range: range,
            withTemplate: "$1<redacted>"
        )
    }
}

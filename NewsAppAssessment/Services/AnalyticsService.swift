import Foundation

protocol AnalyticsServiceProtocol: Sendable {
    func track(_ event: AnalyticsEvent)
}

final class ConsoleAnalyticsService: AnalyticsServiceProtocol {
    private let timestampFormatter: ISO8601DateFormatter
    private let clock: @Sendable () -> Date

    init(clock: @escaping @Sendable () -> Date = Date.init) {
        self.timestampFormatter = ISO8601DateFormatter()
        self.timestampFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.clock = clock
    }

    func track(_ event: AnalyticsEvent) {
        AppLogger.analytics(format(event))
    }

    func format(_ event: AnalyticsEvent) -> String {
        let timestamp = timestampFormatter.string(from: clock())
        let params = event.parameters
        
        guard !params.isEmpty else {
            return "[\(timestamp)] \(event.name)"
        }
        let body = params
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        return "[\(timestamp)] \(event.name) \(body)"
    }
}

struct NoopAnalyticsService: AnalyticsServiceProtocol {
    func track(_ event: AnalyticsEvent) {}
}

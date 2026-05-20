import Testing
@testable import NewsAppAssessment

struct AppLoggerTests {
    @Test func redact_stripsAPIKeyQueryValue() {
        let raw = "GET https://newsdata.io/api/1/latest?country=us&apikey=secret-abc-123&page=2"
        let redacted = AppLogger.redact(raw)
        #expect(!redacted.contains("secret-abc-123"))
        #expect(redacted.contains("apikey=<redacted>"))
        #expect(redacted.contains("country=us"))
        #expect(redacted.contains("page=2"))
    }

    @Test func redact_isCaseInsensitive() {
        let raw = "API call apiKey=ABC123 trailing"
        let redacted = AppLogger.redact(raw)
        #expect(!redacted.contains("ABC123"))
    }

    @Test func redact_preservesNonSensitiveStrings() {
        let raw = "Article loaded id=123 count=10"
        #expect(AppLogger.redact(raw) == raw)
    }

    @Test func redact_handlesEmptyInput() {
        #expect(AppLogger.redact("").isEmpty)
    }
}

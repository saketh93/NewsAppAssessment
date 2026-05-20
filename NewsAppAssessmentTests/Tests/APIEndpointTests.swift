import Testing
@testable import NewsAppAssessment
import Foundation

struct APIEndpointTests {
    private func endpoint(_ key: String? = "test-key") -> APIEndpoint {
        APIEndpoint(keyProvider: StaticAPIKeyProvider(apiKey: key))
    }

    @Test func latest_buildsHTTPSURL() {
        let url = endpoint().latest(country: "us", query: nil, nextPage: nil)
        #expect(url?.scheme == "https")
        #expect(url?.host == "newsdata.io")
    }

    @Test func latest_includesCountryAndKey() {
        let url = endpoint().latest(country: "in", query: nil, nextPage: nil)
        let queryItems = URLComponents(url: url ?? URL(fileURLWithPath: "/"), resolvingAgainstBaseURL: false)?.queryItems ?? []
        let names = queryItems.map(\.name)
        #expect(names.contains("country"))
        #expect(names.contains("apikey"))
        #expect(queryItems.first { $0.name == "country" }?.value == "in")
    }

    @Test func latest_appendsQueryWhenProvided() {
        let url = endpoint().latest(country: "us", query: "ai", nextPage: nil)
        let queryItems = URLComponents(url: url ?? URL(fileURLWithPath: "/"), resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(queryItems.first { $0.name == "q" }?.value == "ai")
    }

    @Test func latest_trimsWhitespaceFromQuery() {
        let url = endpoint().latest(country: "us", query: "   ", nextPage: nil)
        let queryItems = URLComponents(url: url ?? URL(fileURLWithPath: "/"), resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(queryItems.first { $0.name == "q" } == nil)
    }

    @Test func latest_includesPaginationCursor() {
        let url = endpoint().latest(country: "us", query: nil, nextPage: "cursor-abc")
        let queryItems = URLComponents(url: url ?? URL(fileURLWithPath: "/"), resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(queryItems.first { $0.name == "page" }?.value == "cursor-abc")
    }

    @Test func latest_returnsNilWhenKeyMissing() {
        let url = endpoint(nil).latest(country: "us", query: nil, nextPage: nil)
        #expect(url == nil)
    }
}

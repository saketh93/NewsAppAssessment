import Testing
@testable import NewsAppAssessment
import Foundation

struct APIKeyProviderTests {
    @Test func staticProvider_returnsConfiguredValue() {
        let provider = StaticAPIKeyProvider(apiKey: "abc")
        #expect(provider.apiKey == "abc")
    }

    @Test func staticProvider_returnsNilWhenUnset() {
        let provider = StaticAPIKeyProvider(apiKey: nil)
        #expect(provider.apiKey == nil)
    }

    @Test func infoPlistProvider_returnsValueWhenPresent() {
        let provider = InfoPlistAPIKeyProvider(infoKey: "TEST_KEY", lookup: { _ in "real-key" })
        #expect(provider.apiKey == "real-key")
    }

    @Test func infoPlistProvider_ignoresPlaceholderValue() {
        let provider = InfoPlistAPIKeyProvider(infoKey: "TEST_KEY", lookup: { _ in "$(NEWSDATA_API_KEY)" })

        #if DEBUG
        #expect(provider.apiKey != nil)
        #else
        #expect(provider.apiKey == nil)
        #endif
    }

    @Test func infoPlistProvider_ignoresWhitespaceOnlyValue() {
        let provider = InfoPlistAPIKeyProvider(infoKey: "TEST_KEY", lookup: { _ in "   " })
        #if DEBUG
        #expect(provider.apiKey != nil)
        #else
        #expect(provider.apiKey == nil)
        #endif
    }

    @Test func infoPlistProvider_ignoresMissingKey() {
        let provider = InfoPlistAPIKeyProvider(infoKey: "TEST_KEY", lookup: { _ in nil })
        #if DEBUG
        #expect(provider.apiKey != nil)
        #else
        #expect(provider.apiKey == nil)
        #endif
    }
}

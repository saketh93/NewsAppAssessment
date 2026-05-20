import Testing
@testable import NewsAppAssessment
import Foundation

struct AnalyticsServiceTests {
    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
    private func makeService() -> ConsoleAnalyticsService {
        ConsoleAnalyticsService(clock: { [fixedDate] in fixedDate })
    }

    @Test func formatsEventWithoutParameters() {
        let service = makeService()
        let output = service.format(.appLaunched)
        #expect(output.contains("app_launched"))
        #expect(output.hasPrefix("["))
    }

    @Test func formatsEventWithSortedParameters() {
        let service = makeService()
        let output = service.format(.newsLoaded(country: "us", count: 12, durationMS: 340))

        #expect(output.contains("news_loaded"))
        #expect(output.contains("count=12"))
        #expect(output.contains("country=us"))
        #expect(output.contains("duration_ms=340"))
        let countryRange = output.range(of: "country=")
        let countRange = output.range(of: "count=")
        if let countryRange, let countRange {
            #expect(countRange.lowerBound < countryRange.lowerBound)
        } else {
            Issue.record("Expected both keys in output")
        }
    }

    @Test func favoriteEvents_useCorrectName() {
        let service = makeService()
        let added = service.format(.favoriteAdded(articleID: "abc"))
        let removed = service.format(.favoriteRemoved(articleID: "abc"))
        #expect(added.contains("favorite_added"))
        #expect(removed.contains("favorite_removed"))
        #expect(added.contains("article_id=abc"))
    }

    @Test func eventNames_areStable() {
        let cases: [(AnalyticsEvent, String)] = [
            (.appLaunched, "app_launched"),
            (.newsLoaded(country: "us", count: 0, durationMS: 0), "news_loaded"),
            (.newsLoadFailed(country: "us", error: ""), "news_load_failed"),
            (.searchPerformed(country: "us", queryLength: 0), "search_performed"),
            (.articleOpened(articleID: "x"), "article_opened"),
            (.favoriteAdded(articleID: "x"), "favorite_added"),
            (.favoriteRemoved(articleID: "x"), "favorite_removed"),
            (.allFavoritesCleared(count: 0), "all_favorites_cleared"),
            (.countryChanged(from: "us", to: "in"), "country_changed"),
            (.languageChanged(to: "en"), "language_changed"),
            (.themeChanged(to: "Dark"), "theme_changed")
        ]
        for (event, expected) in cases {
            #expect(event.name == expected)
        }
    }

    @Test func noopService_doesNotCrash() {
        let service = NoopAnalyticsService()
        service.track(.appLaunched)
        service.track(.favoriteAdded(articleID: "anything"))
    }
}

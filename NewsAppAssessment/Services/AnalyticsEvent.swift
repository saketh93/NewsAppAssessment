import Foundation

enum AnalyticsEvent: Sendable {
    case appLaunched
    case newsLoaded(country: String, count: Int, durationMS: Int)
    case newsLoadFailed(country: String, error: String)
    case searchPerformed(country: String, queryLength: Int)
    case articleOpened(articleID: String)
    case favoriteAdded(articleID: String)
    case favoriteRemoved(articleID: String)
    case allFavoritesCleared(count: Int)
    case countryChanged(from: String, to: String)
    case languageChanged(to: String)
    case themeChanged(to: String)

    var name: String {
        switch self {
        case .appLaunched: "app_launched"
        case .newsLoaded: "news_loaded"
        case .newsLoadFailed: "news_load_failed"
        case .searchPerformed: "search_performed"
        case .articleOpened: "article_opened"
        case .favoriteAdded: "favorite_added"
        case .favoriteRemoved: "favorite_removed"
        case .allFavoritesCleared: "all_favorites_cleared"
        case .countryChanged: "country_changed"
        case .languageChanged: "language_changed"
        case .themeChanged: "theme_changed"
        }
    }

    var parameters: [String: String] {
        switch self {
        case .appLaunched:
            return [:]
        case let .newsLoaded(country, count, durationMS):
            return ["country": country, "count": "\(count)", "duration_ms": "\(durationMS)"]
        case let .newsLoadFailed(country, error):
            return ["country": country, "error": error]
        case let .searchPerformed(country, queryLength):
            return ["country": country, "query_length": "\(queryLength)"]
        case let .articleOpened(articleID):
            return ["article_id": articleID]
        case let .favoriteAdded(articleID):
            return ["article_id": articleID]
        case let .favoriteRemoved(articleID):
            return ["article_id": articleID]
        case let .allFavoritesCleared(count):
            return ["count": "\(count)"]
        case let .countryChanged(from, toValue):
            return ["from": from, "to": toValue]
        case let .languageChanged(toValue):
            return ["to": toValue]
        case let .themeChanged(toValue):
            return ["to": toValue]
        }
    }
}

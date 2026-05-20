import Combine
import Foundation

@MainActor
final class ArticleDetailViewModel: ObservableObject {
    @Published private(set) var isFavorite: Bool = false
    @Published var toastMessage: String?

    let article: Article
    private let favoritesService: FavoritesServiceProtocol
    private let analytics: AnalyticsServiceProtocol
    private let languageManager: LanguageManager?

    init(article: Article,
         favoritesService: FavoritesServiceProtocol,
         analytics: AnalyticsServiceProtocol = NoopAnalyticsService(),
         languageManager: LanguageManager? = nil) {
        self.article = article
        self.favoritesService = favoritesService
        self.analytics = analytics
        self.languageManager = languageManager
    }
    
    func loadFavoriteState() async {
        isFavorite = await favoritesService.isFavorite(id: article.id)
        analytics.track(.articleOpened(articleID: article.id))
    }

    func toggleFavorite() async {
        await favoritesService.toggle(article)
        isFavorite = await favoritesService.isFavorite(id: article.id)
        analytics.track(isFavorite
                        ? .favoriteAdded(articleID: article.id)
                        : .favoriteRemoved(articleID: article.id))
        let addedKey = Constants.LocalizationKeys.addedToFavorites
        let removedKey = Constants.LocalizationKeys.removedFromFavorites
        toastMessage = isFavorite ? localized(addedKey) : localized(removedKey)
    }

    private func localized(_ key: String) -> String {
        languageManager?.localize(key) ?? NSLocalizedString(key, comment: "")
    }
}

import Combine
import Foundation

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published private(set) var favorites: [Article] = []
    @Published private(set) var isLoading = false

    private let favoritesService: FavoritesServiceProtocol
    private let analytics: AnalyticsServiceProtocol

    init(favoritesService: FavoritesServiceProtocol,
         analytics: AnalyticsServiceProtocol = NoopAnalyticsService()) {
        self.favoritesService = favoritesService
        self.analytics = analytics
    }
    
    func loadFavorites(showLoading: Bool = true) async {
        if showLoading { isLoading = true }
        
        defer { isLoading = false }
        
        let items = await favoritesService.all()
        favorites = items.map(\.asArticle)
    }

    func remove(id: String) async {
        await favoritesService.remove(id: id)
        
        analytics.track(.favoriteRemoved(articleID: id))
        
        await loadFavorites(showLoading: false)
    }

    func removeAll() async {
        let count = favorites.count
        
        for article in favorites {
            await favoritesService.remove(id: article.id)
        }
        
        favorites = []
        analytics.track(.allFavoritesCleared(count: count))
    }
}

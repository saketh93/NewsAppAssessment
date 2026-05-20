@testable import NewsAppAssessment
import Foundation

actor MockFavoritesService: FavoritesServiceProtocol {
    private var store: [String: FavoriteArticle] = [:]

    var toggleCallCount = 0
    var addCallCount = 0
    var removeCallCount = 0

    func all() async -> [FavoriteArticle] {
        Array(store.values)
    }

    func isFavorite(id: String) async -> Bool {
        store[id] != nil
    }

    func add(_ article: Article) async {
        addCallCount += 1
        await store[article.id] = FavoriteArticle(from: article)
    }

    func remove(id: String) async {
        removeCallCount += 1
        store.removeValue(forKey: id)
    }

    func toggle(_ article: Article) async {
        toggleCallCount += 1
        if await isFavorite(id: article.id) {
            await remove(id: article.id)
        } else {
            await add(article)
        }
    }
}

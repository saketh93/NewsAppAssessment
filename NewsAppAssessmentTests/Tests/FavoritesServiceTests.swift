import Testing
@testable import NewsAppAssessment
import Foundation
import SwiftData

@MainActor
struct FavoritesServiceTests {
    @MainActor private func makeService() throws -> FavoritesService {
        let container = try ModelContainer(
            for: FavoriteArticleSD.self, CountryPreference.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return FavoritesService(modelContainer: container)
    }

    @Test(
        "Add stores article by ID",
        arguments: ["svc-a", "svc-b", "svc-c"]
    )
    func add_storesArticle(id: String) async throws {
        let service = try makeService()
        let article = ArticleFactory.make(id: id)

        await service.add(article)

        let isFav = await service.isFavorite(id: id)
        #expect(isFav == true)
    }

    @Test(
        "Remove deletes stored article",
        arguments: ["del-1", "del-2", "del-3"]
    )
    func remove_deletesArticle(id: String) async throws {
        let service = try makeService()
        let article = ArticleFactory.make(id: id)

        await service.add(article)
        await service.remove(id: id)

        let isFav = await service.isFavorite(id: id)
        #expect(isFav == false)
    }

    @Test func toggle_addsAndRemoves() async throws {
        let service = try makeService()
        let article = ArticleFactory.make(id: "svc-toggle")

        await service.toggle(article)
        var isFav = await service.isFavorite(id: article.id)
        #expect(isFav == true)

        await service.toggle(article)
        isFav = await service.isFavorite(id: article.id)
        #expect(isFav == false)
    }

    @Test func all_returnsAllStoredArticles() async throws {
        let service = try makeService()
        let ids = ["all-1", "all-2", "all-3"]

        for id in ids {
            await service.add(ArticleFactory.make(id: id))
        }

        let stored = await service.all().map(\.id)
        for id in ids {
            #expect(stored.contains(id))
        }
    }
}

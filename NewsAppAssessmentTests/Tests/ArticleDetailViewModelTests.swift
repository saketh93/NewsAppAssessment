import Testing
@testable import NewsAppAssessment
import Foundation

@MainActor
struct ArticleDetailViewModelTests {
    private func makeViewModel(id: String, preloaded: Bool = false) async -> ArticleDetailViewModel {
        let service = MockFavoritesService()
        let article = ArticleFactory.make(id: id)
        if preloaded { await service.add(article) }
        let vm = ArticleDetailViewModel(article: article, favoritesService: service, languageManager: nil)
        await vm.loadFavoriteState()
        return vm
    }

    @Test(
        "Initial favorite state loaded correctly",
        arguments: zip(
            ["state-not-fav", "state-is-fav"],
            [false, true]
        )
    )
    func loadFavoriteState_reflectsServiceState(id: String, expectedFav: Bool) async {
        let service = MockFavoritesService()
        let article = ArticleFactory.make(id: id)
        if expectedFav { await service.add(article) }
        let vm = ArticleDetailViewModel(article: article, favoritesService: service, languageManager: nil)

        await vm.loadFavoriteState()

        #expect(vm.isFavorite == expectedFav)
    }

    @Test(
        "Toggle changes isFavorite",
        arguments: [
            ("tog-add", false, true),
            ("tog-remove", true, false)
        ] as [(String, Bool, Bool)]
    )
    func toggleFavorite_changesState(id: String, initial: Bool, expected: Bool) async {
        let service = MockFavoritesService()
        let article = ArticleFactory.make(id: id)
        if initial { await service.add(article) }
        let vm = ArticleDetailViewModel(article: article, favoritesService: service, languageManager: nil)
        await vm.loadFavoriteState()

        await vm.toggleFavorite()

        #expect(vm.isFavorite == expected)
    }

    @Test func toggleFavorite_alwaysSetsToastMessage() async {
        let vm = await makeViewModel(id: "toast-1")
        await vm.toggleFavorite()
        #expect(vm.toastMessage != nil)
    }
}

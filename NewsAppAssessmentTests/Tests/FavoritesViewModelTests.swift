import Testing
@testable import NewsAppAssessment
import Foundation

@MainActor
struct FavoritesViewModelTests {
    func makeViewModel(service: MockFavoritesService = MockFavoritesService()) -> FavoritesViewModel {
        FavoritesViewModel(favoritesService: service)
    }

    @Test func loadFavorites_empty() async {
        let vm = makeViewModel()
        await vm.loadFavorites()
        #expect(vm.favorites.isEmpty)
        #expect(vm.isLoading == false)
    }

    @Test(
        "Load favorites returns correct count",
        arguments: [1, 2, 5]
    )
    func loadFavorites_populatesCorrectCount(count: Int) async {
        let service = MockFavoritesService()
        for i in 0..<count {
            await service.add(ArticleFactory.make(id: "pop-\(i)"))
        }
        let vm = makeViewModel(service: service)
        await vm.loadFavorites()
        #expect(vm.favorites.count == count)
    }

    @Test(
        "Remove deletes correct article",
        arguments: ["rem-a", "rem-b", "rem-c"]
    )
    func remove_deletesArticle(id: String) async {
        let service = MockFavoritesService()
        await service.add(ArticleFactory.make(id: id))

        let vm = makeViewModel(service: service)
        await vm.loadFavorites()
        #expect(vm.favorites.count == 1)

        await vm.remove(id: id)
        #expect(vm.favorites.isEmpty)
    }

    @Test func loadFavorites_showLoadingFalse_doesNotSetLoadingFlag() async {
        let vm = makeViewModel()
        await vm.loadFavorites(showLoading: false)

        #expect(vm.isLoading == false)
    }

    @Test func removeAll_clearsAllFavorites() async {
        let service = MockFavoritesService()
        for i in 1...3 {
            await service.add(ArticleFactory.make(id: "item-\(i)"))
        }
        let vm = makeViewModel(service: service)
        await vm.loadFavorites()
        #expect(vm.favorites.count == 3)

        await vm.removeAll()
        #expect(vm.favorites.isEmpty)
    }
}

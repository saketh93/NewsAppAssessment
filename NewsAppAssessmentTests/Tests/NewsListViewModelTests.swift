import Testing
@testable import NewsAppAssessment
import Foundation

@MainActor
struct NewsListViewModelTests {
    func makeViewModel(
        newsService: MockNewsService = MockNewsService(),
        favoritesService: MockFavoritesService = MockFavoritesService()
    ) -> NewsListViewModel {
        NewsListViewModel(newsService: newsService, favoritesService: favoritesService)
    }

    @Test func initialStateIsIdle() {
        let vm = makeViewModel()
        #expect(vm.loadingState == .idle)
        #expect(vm.articles.isEmpty)
        #expect(vm.searchQuery.isEmpty)
        #expect(!vm.isLoadingMore)
    }

    @Test func loadInitialArticles_success() async {
        let mockNews = MockNewsService()
        let articles = (1...5).map { ArticleFactory.make(id: "\($0)", title: "Article \($0)") }
        mockNews.stubbedResponse = ArticleFactory.makeResponse(articles: articles)

        let vm = makeViewModel(newsService: mockNews)
        await vm.loadInitialArticles()

        #expect(vm.loadingState == .loaded)
        #expect(vm.articles.count == 5)
        #expect(mockNews.fetchCallCount == 1)
    }

    @Test func loadInitialArticles_empty() async {
        let mockNews = MockNewsService()
        mockNews.stubbedResponse = ArticleFactory.makeResponse(articles: [])

        let vm = makeViewModel(newsService: mockNews)
        await vm.loadInitialArticles()

        #expect(vm.loadingState == .empty)
        #expect(vm.articles.isEmpty)
    }

    @Test func loadInitialArticles_failure_setsFailureState() async {
        let mockNews = MockNewsService()
        mockNews.stubbedError = NetworkError.noInternet

        let vm = makeViewModel(newsService: mockNews)
        await vm.loadInitialArticles()

        if case .failure = vm.loadingState {
        } else {
            Issue.record("Expected failure state but got \(vm.loadingState)")
        }
        #expect(vm.articles.isEmpty)
    }

    @Test func loadInitialArticles_failure_setsToastMessage() async {
        let mockNews = MockNewsService()
        mockNews.stubbedError = NetworkError.noInternet

        let vm = makeViewModel(newsService: mockNews)
        await vm.loadInitialArticles()

        #expect(vm.toastMessage != nil)
    }

    @Test func fetchPassesCorrectCountry() async {
        let mockNews = MockNewsService()
        mockNews.stubbedResponse = ArticleFactory.makeResponse()

        let vm = makeViewModel(newsService: mockNews)
        vm.selectedCountry = Country(id: "gb", displayName: "UK", flagEmoji: "🇬🇧")

        await vm.loadInitialArticles()

        #expect(mockNews.lastCountry == "gb")
    }

    @Test func fetchPassesNilQueryWhenEmpty() async {
        let mockNews = MockNewsService()
        mockNews.stubbedResponse = ArticleFactory.makeResponse()

        let vm = makeViewModel(newsService: mockNews)
        await vm.loadInitialArticles()

        #expect(mockNews.lastQuery == nil)
    }

    @Test func retry_resetsAndReloads() async {
        let mockNews = MockNewsService()
        mockNews.stubbedError = NetworkError.noInternet

        let vm = makeViewModel(newsService: mockNews)
        await vm.loadInitialArticles()

        mockNews.stubbedError = nil
        let articles = [ArticleFactory.make()]
        mockNews.stubbedResponse = ArticleFactory.makeResponse(articles: articles)

        await vm.retry()

        #expect(vm.loadingState == .loaded)
        #expect(!vm.articles.isEmpty)
    }

    @Test func hasMorePages_trueWhenNextPageTokenPresent() async {
        let mockNews = MockNewsService()
        let articles = (1...5).map { ArticleFactory.make(id: "\($0)") }
        mockNews.stubbedResponse = ArticleFactory.makeResponse(articles: articles, nextPage: "cursor-abc")

        let vm = makeViewModel(newsService: mockNews)
        await vm.loadInitialArticles()

        #expect(vm.hasMorePages == true)
    }

    @Test func hasMorePages_falseWhenNextPageTokenNil() async {
        let mockNews = MockNewsService()
        let articles = (1...5).map { ArticleFactory.make(id: "\($0)") }
        mockNews.stubbedResponse = ArticleFactory.makeResponse(articles: articles, nextPage: nil)

        let vm = makeViewModel(newsService: mockNews)
        await vm.loadInitialArticles()

        #expect(vm.hasMorePages == false)
    }

    @Test func toggleFavorite_addsToFavorites() async {
        let mockFavorites = MockFavoritesService()
        let vm = makeViewModel(favoritesService: mockFavorites)

        let article = ArticleFactory.make(id: "fav-1")
        await vm.toggleFavorite(article)

        let isFav = await mockFavorites.isFavorite(id: "fav-1")
        #expect(isFav == true)
    }

    @Test func toggleFavorite_removesFromFavorites() async {
        let mockFavorites = MockFavoritesService()
        let article = ArticleFactory.make(id: "fav-2")
        await mockFavorites.add(article)

        let vm = makeViewModel(favoritesService: mockFavorites)
        await vm.refreshFavoriteIDs()
        #expect(vm.isFavorite(article) == true)

        await vm.toggleFavorite(article)

        let isFav = await mockFavorites.isFavorite(id: "fav-2")
        #expect(isFav == false)
    }

    @Test func refreshFavoriteIDs_updatesLocalSet() async {
        let mockFavorites = MockFavoritesService()
        let article = ArticleFactory.make(id: "fav-3")
        await mockFavorites.add(article)

        let vm = makeViewModel(favoritesService: mockFavorites)
        #expect(vm.isFavorite(article) == false)

        await vm.refreshFavoriteIDs()
        #expect(vm.isFavorite(article) == true)
    }

    @Test func removedArticlesAreFiltered() async {
        let mockNews = MockNewsService()
        let good = ArticleFactory.make(id: "good")
        let removed = ArticleFactory.make(id: "bad", title: "[Removed]")
        mockNews.stubbedResponse = ArticleFactory.makeResponse(articles: [good, removed])

        let vm = makeViewModel(newsService: mockNews)
        await vm.loadInitialArticles()

        #expect(vm.articles.count == 1)
        #expect(vm.articles.first?.id == "good")
    }
}


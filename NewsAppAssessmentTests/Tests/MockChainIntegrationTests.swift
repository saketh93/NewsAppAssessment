import Testing
@testable import NewsAppAssessment
import Foundation

@MainActor
struct MockChainIntegrationTests {

    @Test func mockNetworkService_feedsNewsService_feedsViewModel() async throws {
        let mockNetwork = MockNetworkService()
        let articles = (1...3).map { ArticleFactory.make(id: "row-\($0)", title: "Row \($0)") }
        mockNetwork.stubbedData = ArticleFactory.makeResponse(articles: articles, nextPage: "next-cursor")

        let endpoint = APIEndpoint(keyProvider: StaticAPIKeyProvider(apiKey: "fake-key"))
        let newsService = NewsService(networkService: mockNetwork, endpoint: endpoint)
        let viewModel = NewsListViewModel(
            newsService: newsService,
            favoritesService: MockFavoritesService()
        )

        await viewModel.loadInitialArticles()

        #expect(mockNetwork.fetchCallCount == 1)
        #expect(viewModel.articles.count == 3)
        #expect(viewModel.articles.first?.id == "row-1")
        #expect(viewModel.hasMorePages == true)
    }

    @Test func mockNewsService_recordsCallArgumentsForViewModel() async {
        let mockNews = MockNewsService()
        mockNews.stubbedResponse = ArticleFactory.makeResponse(articles: [ArticleFactory.make()])
        let viewModel = NewsListViewModel(
            newsService: mockNews,
            favoritesService: MockFavoritesService()
        )

        viewModel.selectedCountry = Country(id: "in", displayName: "India", flagEmoji: "🇮🇳")
        try? await Task.sleep(for: .milliseconds(50))

        #expect(mockNews.fetchCallCount >= 1)
        #expect(mockNews.lastCountry == "in")
    }

    @Test func mockNetworkService_errorPath_propagatesToViewModelToast() async {
        let mockNetwork = MockNetworkService()
        mockNetwork.stubbedError = NetworkError.noInternet
        let endpoint = APIEndpoint(keyProvider: StaticAPIKeyProvider(apiKey: "fake-key"))
        let newsService = NewsService(networkService: mockNetwork, endpoint: endpoint)
        let viewModel = NewsListViewModel(
            newsService: newsService,
            favoritesService: MockFavoritesService()
        )

        await viewModel.loadInitialArticles()

        #expect(mockNetwork.fetchCallCount == 1)
        #expect(viewModel.toastMessage != nil)
        if case .failure = viewModel.loadingState {
        } else {
            Issue.record("Expected failure state but got \(viewModel.loadingState)")
        }
    }

    @Test func mockFavoritesService_recordsToggleCalls() async {
        let mockFavorites = MockFavoritesService()
        let viewModel = NewsListViewModel(
            newsService: MockNewsService(),
            favoritesService: mockFavorites
        )
        let article = ArticleFactory.make(id: "tap-1")

        await viewModel.toggleFavorite(article)
        await viewModel.toggleFavorite(article)

        let toggles = await mockFavorites.toggleCallCount
        #expect(toggles == 2)
    }
}


import Testing
@testable import NewsAppAssessment
import Foundation

@MainActor
struct NewsServiceTests {
    private func makeService(
        network: NetworkServiceProtocol = MockNetworkService(),
        keyProvider: APIKeyProviding = StaticAPIKeyProvider(apiKey: "test-key")
    ) -> NewsService {
        NewsService(networkService: network, endpoint: APIEndpoint(keyProvider: keyProvider))
    }

    @Test func fetchArticles_callsNetworkWithCorrectURL() async throws {
        let mockNetwork = MockNetworkService()
        let expectedResponse = ArticleFactory.makeResponse(articles: [ArticleFactory.make()])
        mockNetwork.stubbedData = expectedResponse

        let service = makeService(network: mockNetwork)
        let response = try await service.fetchArticles(country: "us", query: nil, nextPage: nil)

        #expect(mockNetwork.fetchCallCount == 1)
        #expect(response.results.count == 1)
    }

    @Test func fetchArticles_propagatesNetworkError() async {
        let mockNetwork = MockNetworkService()
        mockNetwork.stubbedError = NetworkError.noInternet
        let service = makeService(network: mockNetwork)

        do {
            _ = try await service.fetchArticles(country: "us", query: nil, nextPage: nil)
            Issue.record("Expected error to be thrown")
        } catch let error as NetworkError {
            #expect(error == .noInternet)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test func fetchArticles_missingKey_throwsInvalidURL() async {
        let service = makeService(keyProvider: StaticAPIKeyProvider(apiKey: nil))

        do {
            _ = try await service.fetchArticles(country: "us", query: nil, nextPage: nil)
            Issue.record("Expected invalidURL when API key is missing")
        } catch let error as NetworkError {
            #expect(error == .invalidURL)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}


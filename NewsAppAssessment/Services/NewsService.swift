import Foundation

protocol NewsServiceProtocol: Sendable {
    func fetchArticles(country: String, query: String?, nextPage: String?) async throws -> NewsResponse
}

final class NewsService: NewsServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let endpoint: APIEndpoint

    init(networkService: NetworkServiceProtocol, endpoint: APIEndpoint) {
        self.networkService = networkService
        self.endpoint = endpoint
    }

    func fetchArticles(country: String, query: String?, nextPage: String?) async throws -> NewsResponse {
        guard let url = endpoint.latest(country: country, query: query, nextPage: nextPage) else {
            throw NetworkError.invalidURL
        }
        return try await networkService.fetch(NewsResponse.self, from: url)
    }
}

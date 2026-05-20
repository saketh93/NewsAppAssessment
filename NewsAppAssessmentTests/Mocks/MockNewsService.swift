@testable import NewsAppAssessment
import Foundation

final class MockNewsService: NewsServiceProtocol, @unchecked Sendable {
    var stubbedResponse: NewsResponse?
    var stubbedError: Error?
    var fetchCallCount = 0
    var lastCountry: String?
    var lastQuery: String?
    var lastNextPage: String?

    nonisolated func fetchArticles(country: String, query: String?, nextPage: String?) async throws -> NewsResponse {
        fetchCallCount += 1
        lastCountry = country
        lastQuery = query
        lastNextPage = nextPage
        if let error = stubbedError { throw error }
        return stubbedResponse ?? NewsResponse(status: "success", totalResults: 0, results: [], nextPage: nil)
    }
}

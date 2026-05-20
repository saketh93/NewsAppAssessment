@testable import NewsAppAssessment
import Foundation

final class MockNetworkService: NetworkServiceProtocol, @unchecked Sendable {
    var stubbedData: (any Decodable)?
    var stubbedError: Error?
    var fetchCallCount = 0

    nonisolated func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        fetchCallCount += 1
        if let error = stubbedError { throw error }
        guard let data = stubbedData as? T else {
            throw NetworkError.decodingFailed("Mock type mismatch")
        }
        return data
    }
}

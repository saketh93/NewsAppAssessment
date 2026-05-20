import Foundation

protocol NetworkServiceProtocol: Sendable {
    func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T
}

final class NetworkService: NetworkServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let timeoutSeconds: TimeInterval

    init(session: URLSession = .shared, timeoutSeconds: TimeInterval = 20) {
        self.session = session
        self.decoder = JSONDecoder()
        self.timeoutSeconds = timeoutSeconds
    }

    func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        guard url.scheme?.lowercased() == "https" else {
            AppLogger.error("Rejected non-HTTPS request: \(url.absoluteString)")
            throw NetworkError.invalidURL
        }

        AppLogger.network("GET \(url.absoluteString)")

        var request = URLRequest(url: url, timeoutInterval: timeoutSeconds)
        request.httpMethod = "GET"

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            throw NetworkError.noInternet
        } catch {
            throw NetworkError.unknown(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown("Invalid response type.")
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            AppLogger.error("Decoding error: \(error)")
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }
}

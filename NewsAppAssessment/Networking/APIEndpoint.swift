import Foundation

struct APIEndpoint {
    static let baseURL = "https://newsdata.io/api/1"

    private let keyProvider: APIKeyProviding

    init(keyProvider: APIKeyProviding) {
        self.keyProvider = keyProvider
    }

    func latest(country: String, query: String?, nextPage: String?) -> URL? {
        guard let apiKey = keyProvider.apiKey else { return nil }

        var components = URLComponents(string: "\(Self.baseURL)/latest")
        
        var items: [URLQueryItem] = [
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "removeduplicate", value: "1")
        ]
        if let trimmed = query?.trimmingCharacters(in: .whitespaces), !trimmed.isEmpty {
            items.append(URLQueryItem(name: "q", value: trimmed))
        }
        if let nextPage, !nextPage.isEmpty {
            items.append(URLQueryItem(name: "page", value: nextPage))
        }
        components?.queryItems = items
        return components?.url
    }
}

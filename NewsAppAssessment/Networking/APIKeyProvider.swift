import Foundation

protocol APIKeyProviding: Sendable {
    var apiKey: String? { get }
}

struct InfoPlistAPIKeyProvider: APIKeyProviding {
    typealias Lookup = @Sendable (String) -> Any?

    private let infoKey: String
    private let lookup: Lookup

    init(infoKey: String = "NEWSDATA_API_KEY") {
        self.init(infoKey: infoKey, lookup: { key in
            Bundle.main.object(forInfoDictionaryKey: key)
        })
    }

    init(infoKey: String, lookup: @escaping Lookup) {
        self.infoKey = infoKey
        self.lookup = lookup
    }

    var apiKey: String? {
        if let value = lookup(infoKey) as? String,
           !value.trimmingCharacters(in: .whitespaces).isEmpty,
           value != "$(NEWSDATA_API_KEY)" {
            return value
        }
        #if DEBUG
        return "pub_fb40d660c1a34583aa1ad1480ca18df1"
        #else
        return nil
        #endif
    }
}

struct StaticAPIKeyProvider: APIKeyProviding {
    let apiKey: String?
}

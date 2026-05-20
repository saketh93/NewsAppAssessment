import Foundation

struct NewsResponse: Decodable {
    let status: String
    let totalResults: Int
    let results: [Article]
    let nextPage: String?
}

struct Article: Codable, Identifiable, Equatable, Hashable {
    let articleID: String
    let link: String
    let title: String?
    let description: String?
    let content: String?
    let keywords: [String]?
    let creator: [String]?
    let language: String?
    let country: [String]
    let category: [String]
    let datatype: Datatype?
    let fetchedAt: String
    let imageURL: String?
    let sourceID: String?
    let sourceName: String?
    let sourcePriority: Int?
    let sourceURL: String?
    let sourceIcon: String?
    let duplicate: Bool

    enum CodingKeys: String, CodingKey {
        case articleID = "article_id"
        case link, title, description, content, keywords, creator
        case language, country, category, datatype
        case fetchedAt = "fetched_at"
        case imageURL = "image_url"
        case sourceID = "source_id"
        case sourceName = "source_name"
        case sourcePriority = "source_priority"
        case sourceURL = "source_url"
        case sourceIcon = "source_icon"
        case duplicate
    }

    var id: String { articleID }

    var displayTitle: String {
        guard let title, !title.isEmpty else { return "Untitled" }
        return title
    }

    var displayAuthor: String {
        guard let first = creator?.first, !first.isEmpty else { return "Unknown" }
        return first
    }

    var displayDescription: String { description ?? "" }

    var urlToImage: String? { imageURL }
    var url: String? { link }

    var formattedDate: String {
        let candidates = ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd'T'HH:mm:ss"]
        for fmt in candidates {
            let formatter = DateFormatter()
            formatter.dateFormat = fmt
            if let date = formatter.date(from: fetchedAt) {
                let display = DateFormatter()
                display.dateStyle = .medium
                display.timeStyle = .none
                return display.string(from: date)
            }
        }
        return fetchedAt
    }
}

extension Article {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        articleID = try container.decodeIfPresent(String.self, forKey: .articleID) ?? UUID().uuidString
        link = try container.decodeIfPresent(String.self, forKey: .link) ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        keywords = try container.decodeIfPresent([String].self, forKey: .keywords)
        creator = try container.decodeIfPresent([String].self, forKey: .creator)
        language = try container.decodeIfPresent(String.self, forKey: .language)
        country = try container.decodeIfPresent([String].self, forKey: .country) ?? []
        category = try container.decodeIfPresent([String].self, forKey: .category) ?? []
        datatype = try container.decodeIfPresent(Datatype.self, forKey: .datatype)
        fetchedAt = try container.decodeIfPresent(String.self, forKey: .fetchedAt) ?? ""
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        sourceID = try container.decodeIfPresent(String.self, forKey: .sourceID)
        sourceName = try container.decodeIfPresent(String.self, forKey: .sourceName)
        sourcePriority = try container.decodeIfPresent(Int.self, forKey: .sourcePriority)
        sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL)
        sourceIcon = try container.decodeIfPresent(String.self, forKey: .sourceIcon)
        duplicate = try container.decodeIfPresent(Bool.self, forKey: .duplicate) ?? false
    }
}

enum Datatype: String, Codable {
    case news
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = Datatype(rawValue: raw) ?? .unknown
    }
}

struct FavoriteArticle: Codable, Identifiable, Equatable {
    let id: String
    let title: String?
    let description: String?
    let link: String
    let imageURL: String?
    let fetchedAt: String
    let creator: [String]?
    let sourceName: String?
    let country: [String]
    let category: [String]

    nonisolated init(
        id: String,
        title: String?,
        description: String?,
        link: String,
        imageURL: String?,
        fetchedAt: String,
        creator: [String]?,
        sourceName: String?,
        country: [String],
        category: [String]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.link = link
        self.imageURL = imageURL
        self.fetchedAt = fetchedAt
        self.creator = creator
        self.sourceName = sourceName
        self.country = country
        self.category = category
    }

    nonisolated var asArticle: Article {
        Article(
            articleID: id,
            link: link,
            title: title,
            description: description,
            content: nil,
            keywords: nil,
            creator: creator,
            language: nil,
            country: country,
            category: category,
            datatype: .news,
            fetchedAt: fetchedAt,
            imageURL: imageURL,
            sourceID: nil,
            sourceName: sourceName,
            sourcePriority: nil,
            sourceURL: nil,
            sourceIcon: nil,
            duplicate: false
        )
    }
}

extension FavoriteArticle {
    nonisolated init(from article: Article) {
        self.init(
            id: article.articleID,
            title: article.title,
            description: article.description,
            link: article.link,
            imageURL: article.imageURL,
            fetchedAt: article.fetchedAt,
            creator: article.creator,
            sourceName: article.sourceName,
            country: article.country,
            category: article.category
        )
    }
}

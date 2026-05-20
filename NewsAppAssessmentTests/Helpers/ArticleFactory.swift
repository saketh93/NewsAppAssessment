@testable import NewsAppAssessment
import Foundation

enum ArticleFactory {
    static func make(
        id: String = UUID().uuidString,
        title: String = "Test Title",
        description: String = "Test description",
        imageURL: String? = "https://example.com/image.jpg",
        fetchedAt: String = "2024-01-15 10:30:00",
        sourceName: String = "Test Source",
        creator: [String]? = ["Test Author"],
        country: [String] = ["us"],
        category: [String] = ["top"]
    ) -> Article {
        Article(
            articleID: id,
            link: "https://example.com/\(id)",
            title: title,
            description: description,
            content: nil,
            keywords: nil,
            creator: creator,
            language: "en",
            country: country,
            category: category,
            datatype: .news,
            fetchedAt: fetchedAt,
            imageURL: imageURL,
            sourceID: "test-source",
            sourceName: sourceName,
            sourcePriority: 1,
            sourceURL: "https://example.com",
            sourceIcon: nil,
            duplicate: false
        )
    }

    static func makeResponse(
        articles: [Article] = [],
        nextPage: String? = nil
    ) -> NewsResponse {
        NewsResponse(
            status: "success",
            totalResults: articles.count,
            results: articles,
            nextPage: nextPage
        )
    }
}

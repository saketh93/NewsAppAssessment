import Testing
@testable import NewsAppAssessment
import Foundation

struct ArticleDecodingTests {
    private let sampleJSON = """
    {
        "article_id": "aed6a28f15f7f11c7e6c24023db3fb33",
        "link": "https://www.nachrichten.at/kultur/eurovision-song-contest-2026-das-zweite-semifinale-im-liveblog;art16,4171081",
        "title": "Eurovision Song Contest 2026: Das zweite Semifinale im Liveblog",
        "description": "Heute wird die 20 voll gemacht.",
        "content": "ONLY AVAILABLE IN PAID PLANS",
        "keywords": null,
        "creator": ["nachrichten.at"],
        "language": "german",
        "country": ["australia"],
        "category": ["entertainment"],
        "datatype": "news",
        "pubDate": "2026-05-14 19:03:00",
        "pubDateTZ": "UTC",
        "fetched_at": "2026-05-14 19:43:19",
        "image_url": "https://example.com/img.jpg",
        "video_url": null,
        "source_id": "nachrichten_at",
        "source_name": "Nachrichten.at",
        "source_priority": 440582,
        "source_url": "https://www.nachrichten.at",
        "source_icon": "https://example.com/icon.png",
        "duplicate": false
    }
    """

    private func decodeArticle(_ json: String) throws -> Article {
        guard let data = json.data(using: .utf8) else {
            throw NetworkError.decodingFailed("utf8 conversion failed")
        }
        return try JSONDecoder().decode(Article.self, from: data)
    }

    private func decodeResponse(_ json: String) throws -> NewsResponse {
        guard let data = json.data(using: .utf8) else {
            throw NetworkError.decodingFailed("utf8 conversion failed")
        }
        return try JSONDecoder().decode(NewsResponse.self, from: data)
    }

    @Test func decodeArticle_parsesAllFieldsCorrectly() throws {
        let article = try decodeArticle(sampleJSON)

        #expect(article.articleID == "aed6a28f15f7f11c7e6c24023db3fb33")
        #expect(article.title?.hasPrefix("Eurovision Song Contest 2026") == true)
        #expect(!article.displayTitle.isEmpty)
        #expect(article.description?.isEmpty == false)
        #expect(article.content == "ONLY AVAILABLE IN PAID PLANS")
        #expect(article.creator?.first == "nachrichten.at")
        #expect(article.language == "german")
        #expect(article.country == ["australia"])
        #expect(article.category == ["entertainment"])
        #expect(article.datatype == .news)
        #expect(article.fetchedAt == "2026-05-14 19:43:19")
        #expect(article.sourceID == "nachrichten_at")
        #expect(article.sourceName == "Nachrichten.at")
        #expect(article.sourcePriority == 440582)
        #expect(article.duplicate == false)
    }

    @Test func decodeArticle_nullFieldsAreNil() throws {
        let article = try decodeArticle(sampleJSON)
        #expect(article.keywords == nil)
    }

    @Test func decodeNewsResponse_parsesMultipleArticles() throws {
        let responseJSON = """
        {
            "status": "success",
            "totalResults": 1,
            "results": [
                {
                    "article_id": "test-1",
                    "link": "https://example.com/1",
                    "title": "Test Article",
                    "description": "Test desc",
                    "content": null,
                    "keywords": null,
                    "creator": ["author"],
                    "language": "en",
                    "country": ["us"],
                    "category": ["tech"],
                    "datatype": "news",
                    "fetched_at": "2026-05-14 10:00:00",
                    "image_url": null,
                    "source_id": "test_src",
                    "source_name": "Test Source",
                    "source_priority": 100,
                    "source_url": "https://test.com",
                    "source_icon": null,
                    "duplicate": false
                }
            ],
            "nextPage": "page-2"
        }
        """

        let response = try decodeResponse(responseJSON)
        #expect(response.status == "success")
        #expect(response.totalResults == 1)
        #expect(response.results.count == 1)
        #expect(response.results[0].articleID == "test-1")
        #expect(response.results[0].title == "Test Article")
        #expect(response.nextPage == "page-2")
    }

    @Test func decodeArticle_missingOptionalFields_usesDefaults() throws {
        let minimalJSON = """
        {
            "article_id": "minimal-1",
            "link": "https://example.com",
            "country": ["us"],
            "category": ["news"],
            "fetched_at": "2026-05-14 10:00:00"
        }
        """
        let article = try decodeArticle(minimalJSON)
        #expect(article.articleID == "minimal-1")
        #expect(article.title == nil)
        #expect(article.country == ["us"])
        #expect(article.category == ["news"])
    }

    @Test func displayTitle_fallsBackWhenTitleIsNil() throws {
        let minimalJSON = """
        {
            "article_id": "no-title",
            "link": "https://example.com",
            "country": [],
            "category": [],
            "fetched_at": "2026-05-14 10:00:00"
        }
        """
        let article = try decodeArticle(minimalJSON)
        #expect(article.displayTitle == "Untitled")
    }

    @Test func displayAuthor_usesCreatorWhenAvailable() throws {
        let article = try decodeArticle(sampleJSON)
        #expect(article.displayAuthor == "nachrichten.at")
    }

    @Test func displayAuthor_fallsBackWhenCreatorIsNil() throws {
        let minimalJSON = """
        {
            "article_id": "no-author",
            "link": "https://example.com",
            "country": [],
            "category": [],
            "fetched_at": "2026-05-14 10:00:00"
        }
        """
        let article = try decodeArticle(minimalJSON)
        #expect(article.displayAuthor == "Unknown")
    }

    @Test func formattedDate_parsesCorrectly() throws {
        let article = try decodeArticle(sampleJSON)
        let formatted = article.formattedDate
        #expect(!formatted.isEmpty)
        #expect(formatted != "2026-05-14 19:43:19")
    }
}

import Foundation
import Testing
@testable import NewsAppAssessment

struct ArticleModelTests {
    @Test("Article id matches articleID")
    func articleID_matchesArticleID() {
        let article = ArticleFactory.make(id: "test-id-123")

        #expect(article.id == "test-id-123")
    }

    @Test(
        "displayTitle returns fallback or actual title",
        arguments: [
            (title: nil as String?, expected: "Untitled"),
            (title: "", expected: "Untitled"),
            (title: "Real Title", expected: "Real Title")
        ]
    )
    func displayTitle_returnsExpectedValue(
        title: String?,
        expected: String
    ) {
        let article = makeArticle(title: title)

        #expect(article.displayTitle == expected)
    }

    @Test(
        "displayAuthor returns creator or Unknown",
        arguments: [
            (creator: nil as [String]?, expected: "Unknown"),
            (creator: [], expected: "Unknown"),
            (creator: ["Jane Doe"], expected: "Jane Doe")
        ]
    )
    func displayAuthor_returnsExpectedValue(
        creator: [String]?,
        expected: String
    ) {
        let article = ArticleFactory.make(creator: creator)

        #expect(article.displayAuthor == expected)
    }

    @Test(
        "formattedDate parses valid date or returns raw value",
        arguments: [
            (
                input: "2024-06-01 12:00:00",
                shouldReturnRaw: false
            ),
            (
                input: "invalid-date",
                shouldReturnRaw: true
            )
        ]
    )
    func formattedDate_returnsExpectedValue(
        input: String,
        shouldReturnRaw: Bool
    ) {
        let article = ArticleFactory.make(fetchedAt: input)

        if shouldReturnRaw {
            #expect(article.formattedDate == input)
        } else {
            #expect(article.formattedDate != input)
            #expect(!article.formattedDate.isEmpty)
        }
    }

    @Test(
        "displayDescription returns empty string when description is empty",
    )
    func displayDescription_returnsEmptyString() {
        let article = ArticleFactory.make(description: "")

        #expect(article.displayDescription.isEmpty)
    }

    @Test("FavoriteArticle converts back to Article correctly")
    func favoriteArticle_roundTripConversion() {
        let original = ArticleFactory.make(
            id: "rt-1",
            title: "Round Trip"
        )

        let favoriteArticle = FavoriteArticle(from: original)
        let convertedArticle = favoriteArticle.asArticle

        #expect(convertedArticle.id == original.id)
        #expect(convertedArticle.url == original.url)
        #expect(
            convertedArticle.displayTitle
            == original.displayTitle
        )
    }

    @Test(
        "Articles with same IDs are equal",
        arguments: [
            ("eq-1", "eq-1"),
            ("eq-2", "eq-2")
        ]
    )
    func articleEquality_sameIDs_returnsTrue(
        lhsID: String,
        rhsID: String
    ) {
        let lhs = ArticleFactory.make(id: lhsID)
        let rhs = ArticleFactory.make(id: rhsID)

        #expect(lhs == rhs)
    }

    @Test(
        "Articles with different IDs are not equal",
        arguments: [
            ("one", "two"),
            ("abc", "xyz")
        ]
    )
    func articleEquality_differentIDs_returnsFalse(
        lhsID: String,
        rhsID: String
    ) {
        let lhs = ArticleFactory.make(id: lhsID)
        let rhs = ArticleFactory.make(id: rhsID)

        #expect(lhs != rhs)
    }
}

private extension ArticleModelTests {
    func makeArticle(title: String?) -> Article {
        guard let title else {
            return Article(
                articleID: "test-id",
                link: "https://example.com",
                title: nil,
                description: nil,
                content: nil,
                keywords: nil,
                creator: nil,
                language: nil,
                country: [],
                category: [],
                datatype: .news,
                fetchedAt: "2024-01-01 00:00:00",
                imageURL: nil,
                sourceID: nil,
                sourceName: nil,
                sourcePriority: nil,
                sourceURL: nil,
                sourceIcon: nil,
                duplicate: false
            )
        }

        return ArticleFactory.make(title: title)
    }
}

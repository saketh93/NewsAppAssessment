import Foundation
import SwiftData

@Model
final class FavoriteArticleSD {
    @Attribute(.unique) var id: String
    var title: String?
    var articleDescription: String?
    var link: String
    var imageURL: String?
    var fetchedAt: String
    var creator: [String]
    var sourceName: String?
    var country: [String]
    var category: [String]

    init(
        id: String,
        title: String?,
        articleDescription: String?,
        link: String,
        imageURL: String?,
        fetchedAt: String,
        creator: [String],
        sourceName: String?,
        country: [String],
        category: [String]
    ) {
        self.id = id
        self.title = title
        self.articleDescription = articleDescription
        self.link = link
        self.imageURL = imageURL
        self.fetchedAt = fetchedAt
        self.creator = creator
        self.sourceName = sourceName
        self.country = country
        self.category = category
    }
}

extension FavoriteArticleSD {
    convenience init(from fav: FavoriteArticle) {
        self.init(
            id: fav.id,
            title: fav.title,
            articleDescription: fav.description,
            link: fav.link,
            imageURL: fav.imageURL,
            fetchedAt: fav.fetchedAt,
            creator: fav.creator ?? [],
            sourceName: fav.sourceName,
            country: fav.country,
            category: fav.category
        )
    }

    var asFavoriteArticle: FavoriteArticle {
        FavoriteArticle(
            id: id,
            title: title,
            description: articleDescription,
            link: link,
            imageURL: imageURL,
            fetchedAt: fetchedAt,
            creator: creator.isEmpty ? nil : creator,
            sourceName: sourceName,
            country: country,
            category: category
        )
    }
}

import Foundation
import SwiftData

protocol FavoritesServiceProtocol: AnyObject, Sendable {
    func all() async -> [FavoriteArticle]
    
    func isFavorite(id: String) async -> Bool

    func add(_ article: Article) async

    func remove(id: String) async

    func toggle(_ article: Article) async
}

@ModelActor
actor FavoritesService: FavoritesServiceProtocol {
    func all() async -> [FavoriteArticle] {
        let descriptor = FetchDescriptor<FavoriteArticleSD>(
            sortBy: [SortDescriptor(\.fetchedAt, order: .reverse)]
        )
        let items = (try? modelContext.fetch(descriptor)) ?? []
        
        return items.map { item in
            FavoriteArticle(
                id: item.id,
                title: item.title,
                description: item.articleDescription,
                link: item.link,
                imageURL: item.imageURL,
                fetchedAt: item.fetchedAt,
                creator: item.creator.isEmpty ? nil : item.creator,
                sourceName: item.sourceName,
                country: item.country,
                category: item.category
            )
        }
    }

    func isFavorite(id: String) async -> Bool {
        var descriptor = FetchDescriptor<FavoriteArticleSD>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
    }

    func add(_ article: Article) async {
        guard !(await isFavorite(id: article.id)) else { return }
        let model = FavoriteArticleSD(from: FavoriteArticle(from: article))
        modelContext.insert(model)
        try? modelContext.save()
        await AppLogger.info("Added favorite: \(article.id)")
    }

    func remove(id: String) async {
        var descriptor = FetchDescriptor<FavoriteArticleSD>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        if let item = try? modelContext.fetch(descriptor).first {
            modelContext.delete(item)
            try? modelContext.save()
        }
        await AppLogger.info("Removed favorite: \(id)")
    }

    func toggle(_ article: Article) async {
        if await isFavorite(id: article.id) {
            await remove(id: article.id)
        } else {
            await add(article)
        }
    }
}

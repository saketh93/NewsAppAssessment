import Combine
import SwiftData
import SwiftUI

final class AppDependencies: ObservableObject {
    let networkService: NetworkServiceProtocol
    let newsService: NewsServiceProtocol
    let favoritesService: FavoritesServiceProtocol
    let analyticsService: AnalyticsServiceProtocol
    let themeManager: ThemeManager
    let languageManager: LanguageManager
    let modelContainer: ModelContainer
    let keyProvider: APIKeyProviding

    private var cancellables = Set<AnyCancellable>()

    init(
        networkService: NetworkServiceProtocol,
        favoritesService: FavoritesServiceProtocol,
        analyticsService: AnalyticsServiceProtocol,
        themeManager: ThemeManager,
        languageManager: LanguageManager,
        modelContainer: ModelContainer,
        keyProvider: APIKeyProviding
    ) {
        self.networkService = networkService
        self.favoritesService = favoritesService
        self.analyticsService = analyticsService
        self.themeManager = themeManager
        self.languageManager = languageManager
        self.modelContainer = modelContainer
        self.keyProvider = keyProvider

        self.newsService = NewsService(
            networkService: networkService,
            endpoint: APIEndpoint(keyProvider: keyProvider)
        )

        themeManager.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        languageManager.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        themeManager.analytics = analyticsService
        languageManager.analytics = analyticsService
    }
}

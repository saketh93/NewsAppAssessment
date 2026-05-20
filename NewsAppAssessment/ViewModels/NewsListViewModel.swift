import Combine
import Foundation
import SwiftData

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case failure(String)
}

@MainActor
final class NewsListViewModel: ObservableObject {
    @Published private(set) var articles: [Article] = []
    @Published private(set) var loadingState: LoadingState = .idle
    @Published private(set) var isLoadingMore = false
    @Published var searchQuery = ""
    @Published var selectedCountry: Country
    @Published var toastMessage: String?
    @Published private(set) var favoriteIDs: Set<String> = []

    private let newsService: NewsServiceProtocol
    private let favoritesService: FavoritesServiceProtocol
    private let analytics: AnalyticsServiceProtocol
    private let modelContext: ModelContext?
    private let languageManager: LanguageManager?
    private var nextPageToken: String?
    private var cancellables = Set<AnyCancellable>()

    var hasMorePages: Bool { nextPageToken != nil }

    init(newsService: NewsServiceProtocol,
         favoritesService: FavoritesServiceProtocol,
         analytics: AnalyticsServiceProtocol = NoopAnalyticsService(),
         modelContext: ModelContext? = nil,
         languageManager: LanguageManager? = LanguageManager()) {
        self.newsService = newsService
        self.favoritesService = favoritesService
        self.analytics = analytics
        self.modelContext = modelContext
        self.languageManager = languageManager

        if let modelContext {
            let savedID = Self.loadCountryID(from: modelContext)
            selectedCountry = Country.all.first { $0.id == savedID } ?? .default
        } else {
            selectedCountry = .default
        }

        setupBindings()
    }

    private func setupBindings() {
        $selectedCountry
            .dropFirst()
            .sink { [weak self] country in
                guard let self else { return }
                let previous = selectedCountry.id
                saveCountryID(country.id)
                analytics.track(.countryChanged(from: previous, to: country.id))
                reset()
                Task { await self.loadArticles() }
            }
            .store(in: &cancellables)

        $searchQuery
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] query in
                guard let self else { return }
                analytics.track(.searchPerformed(country: selectedCountry.id, queryLength: query.count))
                reset()
                Task { await self.loadArticles() }
            }
            .store(in: &cancellables)
    }
    
    private static func loadCountryID(from context: ModelContext) -> String {
        let items = try? context.fetch(FetchDescriptor<CountryPreference>())
        return items?.first?.countryID ?? ""
    }

    private func saveCountryID(_ id: String) {
        guard let modelContext else { return }
        do {
            let items = try modelContext.fetch(FetchDescriptor<CountryPreference>())
            if let existing = items.first {
                existing.countryID = id
            } else {
                modelContext.insert(CountryPreference(countryID: id))
            }
            try modelContext.save()
        } catch {
            AppLogger.warning("Failed to persist country selection: \(error)")
        }
    }

    func loadInitialArticles() async {
        guard loadingState == .idle else { return }
        await loadArticles()
    }

    func retry() async {
        reset()
        await loadArticles()
    }

    func loadNextPage() async {
        guard !isLoadingMore, hasMorePages else { return }
        await loadArticles(isPaginating: true)
    }

    func toggleFavorite(_ article: Article) async {
        await favoritesService.toggle(article)
        await refreshFavoriteIDs()
        let isFav = favoriteIDs.contains(article.id)
        analytics.track(isFav
                        ? .favoriteAdded(articleID: article.id)
                        : .favoriteRemoved(articleID: article.id))
        let key = isFav
            ? Constants.LocalizationKeys.addedToFavorites
            : Constants.LocalizationKeys.removedFromFavorites
        toastMessage = languageManager?.localize(key) ?? NSLocalizedString(key, comment: "")
    }

    func isFavorite(_ article: Article) -> Bool {
        favoriteIDs.contains(article.id)
    }

    func refreshFavoriteIDs() async {
        let all = await favoritesService.all()
        favoriteIDs = Set(all.map(\.id))
    }

    private func reset() {
        articles = []
        nextPageToken = nil
        loadingState = .idle
    }

    private func loadArticles(isPaginating: Bool = false) async {
        if isPaginating {
            isLoadingMore = true
        } else {
            loadingState = .loading
        }

        defer { isLoadingMore = false }

        let started = Date()
        do {
            let response = try await newsService.fetchArticles(
                country: selectedCountry.id,
                query: searchQuery.nilIfEmpty,
                nextPage: isPaginating ? nextPageToken : nil
            )

            nextPageToken = response.nextPage

            let incoming = response.results.filter { $0.title != "[Removed]" }

            if isPaginating {
                articles.append(contentsOf: incoming)
            } else {
                articles = incoming
            }

            loadingState = articles.isEmpty ? .empty : .loaded
            let elapsedMS = Int(Date().timeIntervalSince(started) * 1000)
            analytics.track(.newsLoaded(country: selectedCountry.id, count: articles.count, durationMS: elapsedMS))
        } catch {
            AppLogger.error("Fetch articles failed for country=\(selectedCountry.id): \(error)")
            analytics.track(.newsLoadFailed(country: selectedCountry.id, error: String(describing: error)))
            let detail = detailedMessage(for: error)
            if !isPaginating { loadingState = .failure(detail) }
            toastMessage = detail
        }
    }

    private func detailedMessage(for error: Error) -> String {
        guard let networkError = error as? NetworkError,
              let languageManager else {
            let key = Constants.LocalizationKeys.somethingWentWrong
            return languageManager?.localize(key) ?? NSLocalizedString(key, comment: "")
        }
        
        return networkError.localizedDescription(manager: languageManager)
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

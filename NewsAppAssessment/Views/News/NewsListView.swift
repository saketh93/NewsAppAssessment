import SwiftData
import SwiftUI

struct NewsListView: View {
    @StateObject private var viewModel: NewsListViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var languageManager: LanguageManager
    private let favoritesService: FavoritesServiceProtocol
    private let analytics: AnalyticsServiceProtocol

    @State private var showCountryPicker = false
    @State private var showSettings = false

    init(newsService: NewsServiceProtocol,
         favoritesService: FavoritesServiceProtocol,
         analytics: AnalyticsServiceProtocol,
         modelContext: ModelContext) {
        self.favoritesService = favoritesService
        self.analytics = analytics
        _viewModel = StateObject(wrappedValue: NewsListViewModel(
            newsService: newsService,
            favoritesService: favoritesService,
            analytics: analytics,
            modelContext: modelContext
        ))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(
                    "\(viewModel.selectedCountry.flagEmoji) \(languageManager.localize(Constants.LocalizationKeys.topHeadlines))"
                )
                .searchable(
                    text: $viewModel.searchQuery,
                    prompt: languageManager.localize(Constants.LocalizationKeys.searchPlaceholder)
                )
                .toolbar { toolbarContent }
                .sheet(isPresented: $showCountryPicker) {
                    CountryPickerView(selectedCountry: $viewModel.selectedCountry)
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView(themeManager: themeManager, languageManager: languageManager)
                }
                .toast(message: $viewModel.toastMessage)
        }
        .task {
            await viewModel.loadInitialArticles()
            await viewModel.refreshFavoriteIDs()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadingState {
        case .idle:
            NewsLoadingView(languageManager: languageManager)
        case .loading where viewModel.articles.isEmpty:
            NewsLoadingView(languageManager: languageManager)
        case .failure(let message):
            EmptyStateView(
                title: languageManager.localize(Constants.LocalizationKeys.errorTitle),
                subtitle: message,
                systemImage: Constants.SFSymbols.exclamationTriangle,
                buttonText: languageManager.localize(Constants.LocalizationKeys.errorRetry),
                retryAction: { Task { await viewModel.retry() } }
            )
            .accessibilityLabel("Error: \(message)")
        case .empty:
            EmptyStateView(
                title: languageManager.localize(Constants.LocalizationKeys.emptyNewsTitle),
                subtitle: languageManager.localize(Constants.LocalizationKeys.emptyNewsSubtitle),
                systemImage: Constants.SFSymbols.newspaper,
                buttonText: languageManager.localize(Constants.LocalizationKeys.errorRetry),
                retryAction: { Task { await viewModel.retry() } }
            )
        default:
            NewsArticleList(
                articles: viewModel.articles,
                isLoadingMore: viewModel.isLoadingMore,
                favoritesService: favoritesService,
                analytics: analytics,
                isFavorite: { viewModel.isFavorite($0) },
                onFavoriteTap: { article in Task { await viewModel.toggleFavorite(article) } },
                onLastItemAppear: { Task { await viewModel.loadNextPage() } },
                onDetailDisappear: { Task { await viewModel.refreshFavoriteIDs() } },
                onRefresh: { await viewModel.retry() }
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                showCountryPicker = true
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.selectedCountry.flagEmoji)
                    Image(systemName: Constants.SFSymbols.chevronDown)
                        .font(.caption)
                }
            }
            .accessibilityIdentifier(Constants.A11yID.countryPickerButton)
            .accessibilityLabel("Select country: \(viewModel.selectedCountry.displayName)")
            .accessibilityHint("Opens country picker")
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: Constants.SFSymbols.gearshape)
            }
            .accessibilityIdentifier(Constants.A11yID.settingsButton)
            .accessibilityLabel("Settings")
        }
    }
}

private struct NewsLoadingView: View {
    let languageManager: LanguageManager

    var body: some View {
        VStack {
            Spacer()
            ProgressView(languageManager.localize(Constants.LocalizationKeys.loading))
                .accessibilityLabel("Loading articles")
            Spacer()
        }
    }
}

private struct NewsArticleList: View {
    let articles: [Article]
    let isLoadingMore: Bool
    let favoritesService: FavoritesServiceProtocol
    let analytics: AnalyticsServiceProtocol
    let isFavorite: (Article) -> Bool
    let onFavoriteTap: (Article) -> Void
    let onLastItemAppear: () -> Void
    let onDetailDisappear: () -> Void
    let onRefresh: @Sendable () async -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(articles) { article in
                    ArticleCardLink(
                        article: article,
                        favoritesService: favoritesService,
                        analytics: analytics,
                        isFavorite: isFavorite(article),
                        onFavoriteTap: { onFavoriteTap(article) },
                        onDetailDisappear: onDetailDisappear
                    )
                    .onAppear {
                        if article.id == articles.last?.id {
                            onLastItemAppear()
                        }
                    }
                }

                if isLoadingMore {
                    ProgressView()
                        .padding()
                        .accessibilityLabel("Loading more articles")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .refreshable { await onRefresh() }
        .accessibilityIdentifier(Constants.A11yID.newsArticleList)
    }
}

private struct ArticleCardLink: View {
    let article: Article
    let favoritesService: FavoritesServiceProtocol
    let analytics: AnalyticsServiceProtocol
    let isFavorite: Bool
    let onFavoriteTap: () -> Void
    let onDetailDisappear: () -> Void

    var body: some View {
        NavigationLink {
            ArticleDetailView(
                article: article,
                favoritesService: favoritesService,
                analytics: analytics
            )
            .onDisappear(perform: onDetailDisappear)
        } label: {
            ArticleRowView(
                article: article,
                isFavorite: isFavorite,
                onFavoriteTap: onFavoriteTap
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(article.displayTitle)
        .accessibilityHint("Opens article detail")
    }
}

import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel: FavoritesViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    private let favoritesService: FavoritesServiceProtocol
    private let analytics: AnalyticsServiceProtocol

    @State private var showClearConfirm = false

    init(favoritesService: FavoritesServiceProtocol,
         analytics: AnalyticsServiceProtocol) {
        self.favoritesService = favoritesService
        self.analytics = analytics
        _viewModel = StateObject(wrappedValue: FavoritesViewModel(
            favoritesService: favoritesService,
            analytics: analytics
        ))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(languageManager.localize(Constants.LocalizationKeys.tabFavorites))
                .toolbar { toolbarContent }
                .confirmationDialog(
                    languageManager.localize(Constants.LocalizationKeys.removeAllConfirmTitle),
                    isPresented: $showClearConfirm,
                    titleVisibility: .visible
                ) {
                    Button(languageManager.localize(Constants.LocalizationKeys.clearAll), role: .destructive) {
                        Task { await viewModel.removeAll() }
                    }
                }
        }
        .task { await viewModel.loadFavorites() }
    }

    @ViewBuilder private var content: some View {
        if viewModel.isLoading {
            FavoritesLoadingView(languageManager: languageManager)
        } else if viewModel.favorites.isEmpty {
            FavoritesEmptyView(languageManager: languageManager)
        } else {
            FavoritesListView(
                favorites: viewModel.favorites,
                favoritesService: favoritesService,
                analytics: analytics,
                languageManager: languageManager,
                onDelete: { id in Task { await viewModel.remove(id: id) } },
                onDisappear: { Task { await viewModel.loadFavorites(showLoading: false) } }
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if !viewModel.favorites.isEmpty {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    Text(languageManager.localize(Constants.LocalizationKeys.clearAll))
                }
                .accessibilityIdentifier(Constants.A11yID.clearAllButton)
                .accessibilityHint("Removes all saved articles")
            }
        }
    }
}

private struct FavoritesLoadingView: View {
    let languageManager: LanguageManager

    var body: some View {
        ProgressView(languageManager.localize(Constants.LocalizationKeys.loading))
            .accessibilityLabel("Loading favorites")
    }
}

private struct FavoritesEmptyView: View {
    let languageManager: LanguageManager

    var body: some View {
        EmptyStateView(
            title: languageManager.localize(Constants.LocalizationKeys.emptyFavoritesTitle),
            subtitle: languageManager.localize(Constants.LocalizationKeys.emptyFavoritesSubtitle),
            systemImage: Constants.SFSymbols.heartSlash,
            buttonText: languageManager.localize(Constants.LocalizationKeys.errorRetry)
        )
    }
}

private struct FavoritesListView: View {
    let favorites: [Article]
    let favoritesService: FavoritesServiceProtocol
    let analytics: AnalyticsServiceProtocol
    let languageManager: LanguageManager
    let onDelete: (String) -> Void
    let onDisappear: () -> Void

    var body: some View {
        List {
            ForEach(favorites) { article in
                NavigationLink {
                    ArticleDetailView(
                        article: article,
                        favoritesService: favoritesService,
                        analytics: analytics
                    )
                    .onDisappear(perform: onDisappear)
                } label: {
                    FavoriteRowView(article: article)
                }
                .accessibilityLabel(article.displayTitle)
            }
            .onDelete { indexSet in
                indexSet.forEach { onDelete(favorites[$0].id) }
            }
        }
        .listStyle(.insetGrouped)
        .accessibilityIdentifier(Constants.A11yID.favoritesList)
    }
}

private struct FavoriteRowView: View {
    let article: Article

    var body: some View {
        HStack(spacing: 12) {
            AsyncImageView(urlString: article.urlToImage)
                .frame(width: 80, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(article.displayTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                Text(article.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

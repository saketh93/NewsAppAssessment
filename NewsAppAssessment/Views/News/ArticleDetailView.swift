import SwiftUI

struct ArticleDetailView: View {
    @StateObject private var viewModel: ArticleDetailViewModel
    @EnvironmentObject private var languageManager: LanguageManager

    init(article: Article,
         favoritesService: FavoritesServiceProtocol,
         analytics: AnalyticsServiceProtocol = NoopAnalyticsService()) {
        _viewModel = StateObject(
            wrappedValue: ArticleDetailViewModel(
                article: article,
                favoritesService: favoritesService,
                analytics: analytics
            )
        )
    }

    var body: some View {
        ScrollView {
            content
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { favoriteToolbar }
        .toast(message: $viewModel.toastMessage)
        .task { await viewModel.loadFavoriteState() }
    }
}

private extension ArticleDetailView {
    var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            ArticleHeroSection(article: viewModel.article)

            ArticleBodySection(
                article: viewModel.article,
                languageManager: languageManager
            )
        }
    }

    @ToolbarContentBuilder
    var favoriteToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            FavoriteButton(
                isFavorite: viewModel.isFavorite,
                action: { Task { await viewModel.toggleFavorite() } }
            )
        }
    }
}

private struct ArticleHeroSection: View {
    let article: Article

    private var accessibilityText: String {
        article.imageURL != nil
        ? "Article image for \(article.displayTitle)"
        : "No image available"
    }

    var body: some View {
        AsyncImageView(urlString: article.urlToImage)
            .frame(height: 240)
            .containerRelativeFrame(.horizontal)
            .clipped()
            .accessibilityLabel(accessibilityText)
    }
}

private struct ArticleBodySection: View {
    let article: Article
    let languageManager: LanguageManager

    private var authorText: String {
        String(
            format: languageManager.localize(Constants.LocalizationKeys.byAuthor),
            article.displayAuthor
        )
    }

    private var readMoreLabel: String {
        languageManager.localize(Constants.LocalizationKeys.readFullArticle)
    }

    private var hasDescription: Bool {
        !article.displayDescription.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ArticleMetaRow(article: article)

            titleView
            authorView

            Divider()

            if hasDescription {
                descriptionView
            }

            ArticleCategoriesSection(categories: article.category)

            ArticleReadMoreSection(
                link: article.link,
                label: readMoreLabel
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

private extension ArticleBodySection {
    var titleView: some View {
        Text(article.displayTitle)
            .font(.title2)
            .fontWeight(.bold)
            .accessibilityAddTraits(.isHeader)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)
    }

    var authorView: some View {
        Text(authorText)
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    var descriptionView: some View {
        Text(article.displayDescription)
            .font(.body)
            .accessibilityLabel("Summary: \(article.displayDescription)")
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct ArticleMetaRow: View {
    let article: Article

    private var sourceName: String? {
        article.sourceName?.uppercased()
    }

    private var formattedDate: String {
        article.formattedDate
    }

    var body: some View {
        HStack {
            if let sourceName {
                Text(sourceName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
                    .accessibilityLabel("Source: \(sourceName)")
            }

            Spacer()

            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityLabel("Published: \(formattedDate)")
        }
    }
}

private struct ArticleCategoriesSection: View {
    let categories: [String]

    private var hasCategories: Bool {
        !categories.isEmpty
    }

    private var accessibilityText: String {
        "Categories: \(categories.joined(separator: ", "))"
    }

    var body: some View {
        if hasCategories {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        categoryPill(for: category)
                    }
                }
            }
            .accessibilityLabel(accessibilityText)
        }
    }
}

private extension ArticleCategoriesSection {
    func categoryPill(for category: String) -> some View {
        Text(category.capitalized)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.12))
            .foregroundColor(.accentColor)
            .clipShape(Capsule())
            .accessibilityLabel("Category: \(category)")
    }
}

private struct ArticleReadMoreSection: View {
    let link: String
    let label: String

    private var url: URL? {
        guard let url = URL(string: link),
              url.scheme?.lowercased() == "https" else { return nil }
        return url
    }

    var body: some View {
        if let url {
            Link(destination: url) {
                Label(label, systemImage: Constants.SFSymbols.safari)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
            .accessibilityLabel(label)
            .accessibilityHint("Opens in browser")
        }
    }
}

private struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    private var iconName: String {
        isFavorite ? Constants.SFSymbols.heartFill : Constants.SFSymbols.heart
    }

    private var iconColor: Color {
        isFavorite ? .red : .primary
    }

    private var accessibilityLabelText: String {
        isFavorite
        ? "Remove from favorites"
        : "Add to favorites"
    }

    private var accessibilityHintText: String {
        isFavorite
        ? "Tap to unfavorite this article"
        : "Tap to save this article"
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
        }
        .accessibilityIdentifier(Constants.A11yID.favoriteToggleButton)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
    }
}

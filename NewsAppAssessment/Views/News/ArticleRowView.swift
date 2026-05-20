import SwiftUI

struct ArticleRowView: View {
    let article: Article
    let isFavorite: Bool
    let onFavoriteTap: () -> Void
    @EnvironmentObject private var languageManager: LanguageManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            thumbnailView
            contentView
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private var thumbnailView: some View {
        AsyncImageView(urlString: article.urlToImage)
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .clipped()
            .accessibilityHidden(true)
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 6) {
            sourceAndDateView
            titleView
            descriptionView
            authorAndFavoriteView
        }
        .padding(12)
    }

    private var sourceAndDateView: some View {
        HStack {
            if let name = article.sourceName {
                Text(name.uppercased())
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
            Spacer()
            Text(article.formattedDate)
                .foregroundColor(.secondary)
        }
        .font(.caption2)
        .accessibilityElement(children: .combine)
    }

    private var titleView: some View {
        Text(article.displayTitle)
            .font(.headline)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var descriptionView: some View {
        Group {
            if !article.displayDescription.isEmpty {
                Text(article.displayDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var authorAndFavoriteView: some View {
        HStack {
            Text(String(format: languageManager.localize(Constants.LocalizationKeys.byAuthor),
                        article.displayAuthor))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Button(action: onFavoriteTap) {
                Image(systemName: isFavorite
                      ? Constants.SFSymbols.heartFill
                      : Constants.SFSymbols.heart)
                    .foregroundColor(isFavorite ? .red : .secondary)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(Constants.A11yID.favoriteToggleButton)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
            .accessibilityHint("Double tap to toggle favorite")
        }
    }
}

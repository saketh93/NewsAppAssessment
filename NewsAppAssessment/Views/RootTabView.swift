import SwiftData
import SwiftUI

struct RootTabView: View {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }

    var body: some View {
        TabView {
            NewsListView(
                newsService: deps.newsService,
                favoritesService: deps.favoritesService,
                analytics: deps.analyticsService,
                modelContext: deps.modelContainer.mainContext
            )
            .tabItem {
                Label(
                    deps.languageManager.localize(Constants.LocalizationKeys.tabNews),
                    systemImage: Constants.SFSymbols.newspaper
                )
            }
            .accessibilityIdentifier(Constants.A11yID.newsTab)

            FavoritesView(
                favoritesService: deps.favoritesService,
                analytics: deps.analyticsService
            )
            .tabItem {
                Label(
                    deps.languageManager.localize(Constants.LocalizationKeys.tabFavorites),
                    systemImage: Constants.SFSymbols.heartFill
                )
            }
            .accessibilityIdentifier(Constants.A11yID.favoritesTab)
        }
        .environmentObject(deps.themeManager)
        .environmentObject(deps.languageManager)
    }
}

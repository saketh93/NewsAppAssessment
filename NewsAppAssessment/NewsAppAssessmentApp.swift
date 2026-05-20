import Combine
import SwiftData
import SwiftUI

@main
struct NewsAppAssessmentApp: App {
    @StateObject private var bootstrap = AppBootstrap()

    init() {
        AppLogger.info("App launched")
    }

    var body: some Scene {
        WindowGroup {
            content
                .task { bootstrap.start() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch bootstrap.state {
        case .loading:
            AppLoadingView()
        case .ready(let deps):
            RootScene(deps: deps)
        case .failed(let message):
            AppFatalView(message: message) { bootstrap.start() }
        }
    }
}

private struct RootScene: View {
    @ObservedObject var deps: AppDependencies

    var body: some View {
        RootTabView(deps: deps)
            .id(deps.languageManager.current.rawValue)
            .preferredColorScheme(deps.themeManager.current.colorScheme)
            .task { deps.analyticsService.track(.appLaunched) }
    }
}

@MainActor
final class AppBootstrap: ObservableObject {
    enum State {
        case loading
        case ready(AppDependencies)
        case failed(String)
    }

    @Published private(set) var state: State = .loading

    func start() {
        state = .loading
        switch buildDependencies() {
        case .success(let deps):
            state = .ready(deps)
        case .failure(let error):
            AppLogger.error("App bootstrap failed: \(error)")
            state = .failed(error.localizedDescription)
        }
    }

    private func buildDependencies() -> Result<AppDependencies, Error> {
        let networkService = NetworkService()
        let analyticsService = ConsoleAnalyticsService()
        let keyProvider = InfoPlistAPIKeyProvider()
        let themeManager = ThemeManager()
        let languageManager = LanguageManager()

        do {
            let container = try Self.makeModelContainer()
            let favoritesService = FavoritesService(modelContainer: container)
            let deps = AppDependencies(
                networkService: networkService,
                favoritesService: favoritesService,
                analyticsService: analyticsService,
                themeManager: themeManager,
                languageManager: languageManager,
                modelContainer: container,
                keyProvider: keyProvider
            )
            return .success(deps)
        } catch {
            return .failure(error)
        }
    }

    private static func makeModelContainer() throws -> ModelContainer {
        do {
            return try ModelContainer(for: FavoriteArticleSD.self, CountryPreference.self)
        } catch {
            AppLogger.error("Persistent store unavailable, falling back to in-memory: \(error)")
        }

        return try ModelContainer(
            for: FavoriteArticleSD.self,
            CountryPreference.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}

private struct AppLoadingView: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .accessibilityLabel("Starting app")
    }
}

private struct AppFatalView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            Text("We could not start the app")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Retry app start")
        }
        .padding()
    }
}

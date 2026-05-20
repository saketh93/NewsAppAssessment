# APP_STRUCTURE.md — Architecture & Flow

## High-level structure

```
NewsAppAssesmentApp  (@main)
│
├── AppBootstrap                 (@MainActor ObservableObject)
│   └── state: .loading | .ready(AppDependencies) | .failed(String)
│
├── AppLoadingView               (splash while bootstrap runs)
├── AppFatalView                 (retryable fatal-state UI; replaces fatalError)
│
└── RootScene  (@ObservedObject deps)
    └── RootTabView (id-keyed off languageManager.current, preferredColorScheme from themeManager)
        ├── [Tab 1] NewsListView
        └── [Tab 2] FavoritesView

AppDependencies  (composition root, no singletons)
├── NetworkService               (URLSession, HTTPS-only, 20s timeout)
├── APIKeyProviding              (InfoPlistAPIKeyProvider | StaticAPIKeyProvider)
├── APIEndpoint                  (URL builder; takes APIKeyProviding)
├── NewsService                  (uses NetworkService + APIEndpoint)
├── FavoritesService             (@ModelActor — SwiftData)
├── AnalyticsServiceProtocol     (ConsoleAnalyticsService → AppLogger)
├── ThemeManager                 (@MainActor — Light / Dark / System)
└── LanguageManager              (@MainActor — EN / ES / FR / DE)
```

`NewsAppAssesmentApp` owns `AppBootstrap` as a `@StateObject`. Bootstrap constructs `AppDependencies` once on first `.task`; all services are stored by protocol, and concrete types are constructed only inside `AppBootstrap.buildDependencies()`.

`RootScene` exists specifically so the app body observes `deps` directly (`@ObservedObject var deps`). Without it, the `case .ready(let deps)` let-binding in the App body does not observe `deps`, and `.preferredColorScheme(deps.themeManager.current.colorScheme)` does not react when the user changes theme inside the running app.

---

## App bootstrap flow

```
NewsAppAssesmentApp.init()
    └── AppLogger.info("App launched")
        ▼
WindowGroup body
    └── @ViewBuilder content (switch bootstrap.state)
        ├── .loading  → AppLoadingView
        ├── .ready    → RootScene(deps:)
        └── .failed   → AppFatalView(message:, retry:)

.task { bootstrap.start() }
    └── AppBootstrap.buildDependencies()
        ├── NetworkService()
        ├── ConsoleAnalyticsService()
        ├── InfoPlistAPIKeyProvider()
        ├── ThemeManager()
        ├── LanguageManager()
        ├── AppBootstrap.makeModelContainer()
        │       try ModelContainer(disk)
        │       ├── success → use it
        │       └── failure → AppLogger.error + try in-memory fallback
        └── FavoritesService(modelContainer:)
```

No `fatalError` / `preconditionFailure`. Disk failure → in-memory fallback (logged). Both failures → `AppFatalView` with retry; user sees a recoverable error screen instead of a crash.

---

## Data flow — news fetch

```
API (newsdata.io)
    │ HTTPS, TLS 1.2+, FS-required (ATS scoped exception)
    ▼
NetworkService.fetch()           — URLSession, HTTPS scheme check, status validation, decoding
    │
    ▼
NewsService.fetchArticles()      — calls APIEndpoint.latest(country:, query:, nextPage:)
    │
    ▼
NewsListViewModel.loadArticles() — @Published articles, loadingState, nextPageToken
    │   ├── analytics.track(.newsLoaded / .newsLoadFailed)
    │   └── toastMessage = detailedMessage(for: error)
    │
    ▼
NewsListView                     — observes the VM via @StateObject
    └── NewsArticleList          — LazyVStack + .refreshable (pull-to-refresh) + infinite scroll trigger
        └── ArticleCardLink      — NavigationLink to ArticleDetailView
            └── ArticleRowView   — card UI + heart button
```

`detailedMessage(for:)` prefers the typed `NetworkError.errorDescription` (localized) over the generic "Something went wrong" fallback, satisfying both the PDF spec and the "show meaningful info to user" requirement.

`.refreshable { await viewModel.retry() }` on the news `ScrollView` provides pull-to-refresh; `retry()` resets cursor + reloads page 1.

---

## Favorites flow

```
User taps heart in list or detail
    │
    ▼
FavoritesService.toggle(article)    — actor-isolated, SwiftData write
    │   └── analytics.track(.favoriteAdded / .favoriteRemoved)
    │
    ▼
NewsListViewModel.refreshFavoriteIDs()
    │   └── @Published favoriteIDs: Set<String>
    │
    ▼
ArticleRowView re-renders          — heart/favorite icon updates
```

```
FavoritesView
    └── FavoritesViewModel.loadFavorites()
        ├── showLoading: true   → ProgressView
        └── showLoading: false  → silent refresh, no flicker
            └── FavoritesListView
                ├── swipe → onDelete → viewModel.remove(id:)
                └── toolbar → Clear All → viewModel.removeAll()
                    └── analytics.track(.allFavoritesCleared(count:))
```

---

## Theme reactivity

```
SettingsView (sheet)
    └── ThemeRow tap → themeManager.current = .light | .dark | .system
        ├── UserDefaults["selected_theme"] = rawValue
        ├── analytics.track(.themeChanged(to:))
        └── ThemeManager.objectWillChange fires
            │
            ├── RootScene re-renders (observes deps → forwards themeManager changes)
            │   └── .preferredColorScheme(themeManager.current.colorScheme)
            │       ├── .light / .dark → window forced to that scheme
            │       └── .system        → nil → window defers to OS
            │
            └── SettingsView body re-renders
                └── .modifier(SchemeOverride(scheme: themeManager.current.colorScheme))
                    ├── scheme != nil → .colorScheme(scheme)  (env override on sheet)
                    └── scheme == nil → no override; sheet inherits from window
```
---

## Concurrency model

```
Main Actor (@MainActor)
├── AppBootstrap            bootstrap.state mutations
├── RootScene
├── NewsListViewModel       @Published state
├── ArticleDetailViewModel
├── FavoritesViewModel
├── ThemeManager
└── LanguageManager

Model Actor (@ModelActor)
└── FavoritesService        serialised SwiftData writes
                              add / remove / toggle / all / isFavorite

Structured concurrency
├── Task { await viewModel.loadInitialArticles() }   — .task modifier
├── Task { await viewModel.loadNextPage() }          — infinite-scroll
├── Task { await viewModel.toggleFavorite(_:) }      — heart tap
├── .refreshable { await viewModel.retry() }         — pull-to-refresh
└── Task { try? await Task.sleep(...) }              — toast auto-dismiss
```

---

## Localization flow

```
SettingsView → LanguageManager.current = .french
    │
    ├── UserDefaults["selected_language"] = "fr"
    ├── UserDefaults["AppleLanguages"]    = ["fr"]
    └── analytics.track(.languageChanged(to: "fr"))
    │
    ▼
RootScene body
    └── RootTabView
            .id(deps.languageManager.current.rawValue)   ← forces full rebuild
    │
    ▼
LanguageManager.bundle → fr.lproj Bundle
    │
    ▼
NSLocalizedString(key, bundle: frBundle, comment: "") returns French text
```

Supported language codes: `en`, `es`, `fr`, `de`. Add a new language by creating `<code>.lproj/Localizable.strings` and adding the case to `AppLanguage`.

---

## Error handling

```
URLSession failure ─┐
URLError.notConnectedToInternet → NetworkError.noInternet
Decoding failure ───┤
Non-2xx status ─────┼─► NetworkError (typed, Equatable, LocalizedError)
HTTPS scheme reject ┤        │
401 unauthorized ───┘        ▼
                         AppLogger.error(...)
                             │
                             ▼
                         NewsListViewModel.detailedMessage(for:)
                             │
                             ▼
                         toastMessage (specific localized text)
                         loadingState.failure (specific localized text)
                             │
                             ▼
                         EmptyStateView (with Retry) + ToastView


## Analytics flow

```
VM / Manager
    │ analytics.track(.someEvent(...))
    ▼
AnalyticsServiceProtocol
    │
    ├── ConsoleAnalyticsService (production / default)
    │   └── format(event) → "[2026-01-01T00:00:00Z] event_name k=v …"
    │       └── AppLogger.analytics(...)
    │
    └── NoopAnalyticsService    (tests / previews)
```

Tracked events (`AnalyticsEvent` cases):
`app_launched`, `news_loaded`, `news_load_failed`, `search_performed`,
`article_opened`, `favorite_added`, `favorite_removed`, `all_favorites_cleared`,
`country_changed`, `language_changed`, `theme_changed`.

---

## Navigation structure

```
RootScene
└── RootTabView
    ├── Tab 1: News
    │   └── NavigationStack
    │       ├── NewsListView
    │       │   ├── Toolbar: country picker (leading) + settings (trailing)
    │       │   ├── .searchable (debounced 400 ms)
    │       │   ├── .refreshable (pull-to-refresh)
    │       │   ├── Sheet: CountryPickerView
    │       │   └── Sheet: SettingsView (SchemeOverride applied)
    │       └── ArticleDetailView (pushed)
    │
    └── Tab 2: Favorites
        └── NavigationStack
            ├── FavoritesView
            │   ├── Swipe-to-delete on rows
            │   └── Toolbar: Clear All (destructive)
            └── ArticleDetailView (pushed)
```

---

## SwiftData persistence

| Model | Purpose | File |
|---|---|---|
| `FavoriteArticleSD` | Saved articles, unique by `id` | [FavoriteArticleSD.swift](NewsAppAssesment/Models/FavoriteArticleSD.swift) |
| `CountryPreference` | Persistent selected country | [CountryPreference.swift](NewsAppAssesment/Models/CountryPreference.swift) |

Both schemas are registered in a single `ModelContainer` built once in `AppBootstrap.makeModelContainer()`. The container falls back to an in-memory store when the on-disk store cannot be opened (logged, never silent, never `fatalError` / `preconditionFailure`).

---

## Security posture

| Layer | Control |
|---|---|
| Transport | ATS: `NSAllowsArbitraryLoads=false` + scoped `newsdata.io` exception requiring TLS 1.2 + Forward Secrecy |
| Runtime | `NetworkService.fetch` rejects any non-HTTPS URL before the request leaves the device |
| Secrets | `NEWSDATA_API_KEY` lives in `Configs/NewsApp.xcconfig` → `Info.plist` → `InfoPlistAPIKeyProvider`. DEBUG-only fallback dev key; release fails closed (`NetworkError.invalidURL`) when no key is configured |
| Logging | `AppLogger.redact(_:)` strips `apikey=…` from every log line emitted via the centralised logger |
| Storage | SwiftData store contains only public article metadata. No PII, no tokens, no Keychain entries |
| Dependencies | Zero third-party runtime packages |

---

## Dependency graph

```
NewsAppAssesmentApp
    └── AppBootstrap
            └── AppDependencies
                    │
                    ├── NetworkService
                    ├── APIKeyProviding (InfoPlistAPIKeyProvider)
                    ├── APIEndpoint(keyProvider:)
                    ├── NewsService(networkService:, endpoint:)
                    ├── FavoritesService (@ModelActor)
                    ├── AnalyticsServiceProtocol (ConsoleAnalyticsService)
                    ├── ThemeManager
                    └── LanguageManager
                            │
                            ▼
NewsListViewModel      ── newsService, favoritesService, analytics, modelContext, languageManager
ArticleDetailViewModel ── favoritesService, analytics, languageManager
FavoritesViewModel     ── favoritesService, analytics
```

---

## File map (current)

```
NewsAppAssesment/
├── App/
│   └── AppDependencies.swift              (composition root)
├── Assets.xcassets/
│   └── AppIcon.appiconset/                (universal AppIcon.png + Dark + Tinted variants)
├── Launch Screen.storyboard
├── Models/
│   ├── Article.swift                      (value type + decoding fallbacks)
│   ├── Country.swift                      (ISO 3166-1 list)
│   ├── CountryPreference.swift            (SwiftData)
│   └── FavoriteArticleSD.swift            (SwiftData)
├── Networking/
│   ├── APIEndpoint.swift                  (URL builder, takes APIKeyProviding)
│   ├── APIKeyProvider.swift               (DIP for the API key source)
│   ├── NetworkError.swift                 (typed, localized, Equatable)
│   └── NetworkService.swift               (HTTPS-only URLSession wrapper, 20s timeout)
├── NewsAppAssesmentApp.swift              (App entry, AppBootstrap, RootScene, AppFatalView)
├── Services/
│   ├── AnalyticsEvent.swift               (typed event enum)
│   ├── AnalyticsService.swift             (Console + Noop impls)
│   ├── FavoritesService.swift             (@ModelActor — SwiftData)
│   └── NewsService.swift
├── ViewModels/
│   ├── ArticleDetailViewModel.swift
│   ├── FavoritesViewModel.swift
│   └── NewsListViewModel.swift
├── Views/
│   ├── RootTabView.swift
│   ├── Common/
│   │   ├── AsyncImageView.swift
│   │   ├── CountryPickerView.swift
│   │   ├── EmptyStateView.swift
│   │   ├── SettingsView.swift             (SchemeOverride for sheet theme reactivity)
│   │   └── ToastView.swift
│   ├── Favorites/
│   │   └── FavoritesView.swift
│   └── News/
│       ├── ArticleDetailView.swift
│       ├── ArticleRowView.swift
│       └── NewsListView.swift             (pull-to-refresh + infinite scroll)
├── Utilities/
│   ├── AppLogger.swift                    (OSLog + apikey redaction)
│   ├── Constants.swift                    (SF symbols, A11yID, l10n keys)
│   ├── LanguageManager.swift
│   └── ThemeManager.swift                 (UITraitCollection-aware default)
├── Info.plist                             (ATS scoped, UILaunchStoryboardName)
└── Resources/
    ├── en.lproj/Localizable.strings
    ├── es.lproj/Localizable.strings
    ├── fr.lproj/Localizable.strings
    └── de.lproj/Localizable.strings
```

```
NewsAppAssesmentTests/
├── Helpers/
│   └── ArticleFactory.swift               (factory for mock articles + responses)
├── Mocks/
│   ├── MockFavoritesService.swift         (actor; records add/remove/toggle counts)
│   ├── MockNetworkService.swift           (stubs data / error; records fetch count)
│   └── MockNewsService.swift              (stubs response / error; records last args)
├── NewsAppAssesmentTests.swift            (index file)
└── Tests/
    ├── AnalyticsServiceTests.swift
    ├── APIEndpointTests.swift
    ├── APIKeyProviderTests.swift
    ├── AppLoggerTests.swift               (redaction)
    ├── ArticleDecodingTests.swift         (real newsdata.io JSON)
    ├── ArticleDetailViewModelTests.swift
    ├── ArticleModelTests.swift
    ├── FavoritesServiceTests.swift        (real in-memory SwiftData)
    ├── FavoritesViewModelTests.swift
    ├── MockChainIntegrationTests.swift    (MockNetwork → NewsService → ViewModel)
    ├── NetworkErrorTests.swift
    ├── NewsListViewModelTests.swift
    └── NewsServiceTests.swift
```

```
NewsAppAssesmentUITests/
├── NewsAppAssesmentUITests.swift          (XCTest — XCUIApplication requires it)
└── TestProjectUITestsLaunchTests.swift    (XCTest — launch screenshot)
```

> UI tests stay on XCTest because Swift Testing's `_Testing_Unavailable` module is intentionally missing from the XCUITest toolchain. All unit tests use Swift Testing (`@Suite`, `@Test`, `#expect`).


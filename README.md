# NewsAppAssessment

SwiftUI / Swift Concurrency news app built for the WSA iOS Engineering Assignment. The full requirement document is included in this repository.

## At a glance

| Aspect | Decision |
|---|---|
| UI | SwiftUI, NavigationStack, two tabs (News / Favorites) |
| State | `@MainActor` view models, `@ObservableObject`, `@Published` |
| Concurrency | `async/await` end-to-end; favorites behind a `@ModelActor actor` |
| Persistence | SwiftData (`FavoriteArticleSD`, `CountryPreference`) |
| Networking | `URLSession` + a thin protocol layer; cursor pagination |
| Localization | `.lproj` bundles for `en` / `es` / `fr` / `de` |
| Theming | Light / Dark / System with live reload |
| Logging | `OSLog`-backed `AppLogger` (no `print` in app code) |
| Analytics | Protocol + console implementation (`ConsoleAnalyticsService`) |
| Testing | Swift Testing (`@Suite`, `@Test`, `#expect`) — unit + UI |
| Quality | SwiftLint zero-warning config; `force_unwrapping` = error |
| Security | HTTPS-only, ATS scoped, API key injected via `xcconfig` |
| Dependencies | **None.** Apple frameworks only. |

---

## Quick start

```bash
open NewsAppAssessment.xcodeproj
# Select an iPhone simulator and press ⌘R
```

CLI build / test:

```bash
xcodebuild -project NewsAppAssessment.xcodeproj \
           -scheme NewsAppAssessment \
           -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
           build

xcodebuild test \
           -project NewsAppAssessment.xcodeproj \
           -scheme NewsAppAssessment \
           -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### API key

The app reads `NEWSDATA_API_KEY` from `Config.xcconfig` and exposes it through `Info.plist`. A documented developer key is bundled as a DEBUG-only fallback so the project runs immediately. For a release build, set your own key:

```text
# Config.xcconfig
NEWSDATA_API_KEY = <your-newsdata-io-key>
```

A missing key in `RELEASE` causes `NewsService.fetchArticles` to throw `NetworkError.invalidURL` and the UI to show a localized error toast. The app never attempts an unauthenticated request.

---

## Architecture in one paragraph

`NewsAppAssessmentApp` constructs the dependency graph in a single composition root (`AppDependencies`). Each collaborator — `NetworkService`, `NewsService`, `FavoritesService`, `AnalyticsService`, `ThemeManager`, `LanguageManager`, `APIKeyProviding` — is held **by protocol**, so substitution in tests or future remoting is trivial. SwiftUI views receive their services through their initializers; view models are `@MainActor` and `final`. Favorites mutation is serialized inside a `@ModelActor actor` so concurrent toggles can't race on the SwiftData context. See [APP_STRUCTURE.md](APP_STRUCTURE.md) for diagrams.

---

## Testing

- Unit tests: `NewsAppAssessmentTests/Tests/*` — Swift Testing (`@Test`, `#expect`). Coverage spans model decoding, networking, services, every view model, and the analytics / API-key plumbing.
- UI tests: `NewsAppAssessmentUITests/` — Swift Testing `@Suite` driving `XCUIApplication`, using stable accessibility identifiers from `Constants.A11yID`.
- Mocks: protocol-conforming doubles in `NewsAppAssessmentTests/Mocks/`. No `URLProtocol` stubs needed because services are wrapped by protocols.

```bash
# Run the entire test plan
xcodebuild test \
    -project NewsAppAssessment.xcodeproj \
    -scheme NewsAppAssessment \
    -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## Linting

SwiftLint config lives at the repo root in `.swiftlint.yml`. `force_cast`, `force_try`, and `force_unwrapping` are all promoted to **error**. To check locally:

```bash
brew install swiftlint
swiftlint --strict --config .swiftlint.yml
```

The project is intentionally zero-warning. New work that introduces warnings will fail review.

---

## Logging & analytics

- `AppLogger` writes to `OSLog` under category-specific subsystems (`Network`, `UI`, `Error`, `Warning`, `Analytics`, `General`). The logger automatically redacts the `apikey=…` query parameter from anything it emits.
- `ConsoleAnalyticsService` formats `AnalyticsEvent` values as a single readable line (`[timestamp] event_name key=value …`) and routes them through the analytics category of `AppLogger`. By design it does **not** ship events anywhere — the scope is "print formatted data to console", per the assignment brief.

Open `Console.app` on macOS to view all log lines from the simulator.

---

## Localization

Strings live in `NewsAppAssessment/Resources/<lang>.lproj/Localizable.strings`. To add a new key, update **all four** files (English, Spanish, French, German), then expose it via `Constants.LocalizationKeys`. Look up at call sites with `languageManager.localize(_:)`. New languages are added by:
1. Creating a new `<code>.lproj/Localizable.strings`.
2. Adding the case to `AppLanguage` in `LanguageManager.swift`.

---

## Accessibility

Every interactive element carries an `accessibilityLabel` and, where helpful, an `accessibilityHint`. Stable identifiers are exposed for UI tests via `Constants.A11yID`. The Favorites list and News list both have accessibility identifiers (`favorites_list`, `news_article_list`) so UI tests are stable across copy changes.

---

## Project layout

```
NewsAppAssessment/
├── App/            Composition root (AppDependencies)
├── Models/         Article + SwiftData entities
├── Networking/     URLSession layer, API key provider, endpoint, errors
├── Services/       NewsService, FavoritesService, AnalyticsService
├── ViewModels/     @MainActor VMs for News / Favorites / Detail
├── Views/          SwiftUI views grouped by feature
├── Utilities/      AppLogger, ThemeManager, LanguageManager, Constants
└── Resources/      *.lproj/Localizable.strings
```

```
NewsAppAssessmentTests/        Swift Testing — unit tests + mocks + factories
NewsAppAssessmentUITests/      Swift Testing — UI suite (drives XCUIApplication)
NewsAppAssessment/             Config.xcconfig (build-time API key)
.swiftlint.yml                 Zero-warning lint config
```

---

## Known assumptions & trade-offs

- The bundled developer API key is `pub_d9ca1c31c0234ac6a0bcfe6fa91bbe86` (publicly known sample). Replace with your own for non-trivial usage. The free tier rate-limits aggressively — empty lists or 429 responses are expected behavior, not bugs.
- newsdata.io paginates by opaque cursor, so we cannot show "page 3 of N" UX. We show an inline spinner at the bottom of the list as the next cursor loads.
- "Something went wrong" is the **fallback** toast; the app prefers the typed `NetworkError.errorDescription` (localized) when one is available, satisfying both the PDF requirement and the friendlier-error goal.
- SwiftData failures fall back to an in-memory store with a logged warning. Favorites won't survive a relaunch in that degraded state, but the app keeps working instead of crashing.

---

## License

Provided for assessment purposes only. See your organization's policy for distribution.


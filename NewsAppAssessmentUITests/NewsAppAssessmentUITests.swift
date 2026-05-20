import XCTest

@MainActor
final class NewsAppAssesmentUITests: XCTestCase {
    private var app: XCUIApplication?

    override func setUpWithError() throws {
        continueAfterFailure = false
        let application = XCUIApplication()
        application.launchArguments += ["--uitesting"]
        application.launch()
        app = application
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func resolvedApp() throws -> XCUIApplication {
        guard let app else {
            throw XCTSkip("App was not initialised in setUp")
        }
        return app
    }

    func testTabBar_showsNewsAndFavoritesTabs() throws {
        let app = try resolvedApp()
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)
        XCTAssertTrue(tabBar.buttons.element(boundBy: 0).exists)
        XCTAssertTrue(tabBar.buttons.element(boundBy: 1).exists)
    }

    func testTabBar_switchToFavoritesTab() throws {
        let app = try resolvedApp()
        FavoritesScreen(app: app).open()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 3))
    }

    func testNewsScreen_navigationBarExists() throws {
        let app = try resolvedApp()
        XCTAssertTrue(NewsScreen(app: app).navigationBar.waitForExistence(timeout: 5))
    }

    func testNewsScreen_searchBarExists() throws {
        let app = try resolvedApp()
        XCTAssertTrue(NewsScreen(app: app).searchField.waitForExistence(timeout: 5))
    }

    func testNewsScreen_countryPickerButtonOpensSheet() throws {
        let app = try resolvedApp()
        let news = NewsScreen(app: app)
        XCTAssertTrue(news.countryPickerButton.waitForExistence(timeout: 5))

        news.countryPickerButton.tap()
        let picker = CountryPickerScreen(app: app)
        XCTAssertTrue(picker.navigationBar.waitForExistence(timeout: 3))

        picker.cancelButton.tap()
        XCTAssertFalse(picker.navigationBar.exists)
    }

    func testNewsScreen_settingsButtonOpensSheet() throws {
        let app = try resolvedApp()
        let news = NewsScreen(app: app)
        XCTAssertTrue(news.settingsButton.waitForExistence(timeout: 5))

        news.settingsButton.tap()
        let settings = SettingsScreen(app: app)
        XCTAssertTrue(settings.navigationBar.waitForExistence(timeout: 3))

        settings.doneButton.tap()
        XCTAssertFalse(settings.navigationBar.exists)
    }

    func testSettingsSheet_showsAppearanceAndLanguageSections() throws {
        let app = try resolvedApp()
        NewsScreen(app: app).settingsButton.tap()
        let settings = SettingsScreen(app: app)
        XCTAssertTrue(settings.navigationBar.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Appearance"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Language"].waitForExistence(timeout: 2))
        settings.doneButton.tap()
    }

    func testCountryPicker_showsCountryRows() throws {
        let app = try resolvedApp()
        NewsScreen(app: app).countryPickerButton.tap()
        let picker = CountryPickerScreen(app: app)
        XCTAssertTrue(picker.navigationBar.waitForExistence(timeout: 3))
        XCTAssertTrue(picker.row(containing: "United States").waitForExistence(timeout: 3))
        picker.cancelButton.tap()
    }

    func testFavoritesScreen_navigationTitle() throws {
        let app = try resolvedApp()
        FavoritesScreen(app: app).open()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 3))
    }

    func testFavoritesScreen_emptyStateShownWhenNoFavorites() throws {
        let app = try resolvedApp()
        FavoritesScreen(app: app).open()
        clearAllFavoritesIfNeeded(in: app)
        XCTAssertTrue(app.staticTexts["No Favorites Yet"].waitForExistence(timeout: 5))
    }

    func testNewsScreen_tappingArticleOpensDetail() throws {
        let app = try resolvedApp()
        let list = app.scrollViews[A11yID.newsArticleList]
        guard list.waitForExistence(timeout: 8) else { return }

        let firstLink = list.buttons.firstMatch
        guard firstLink.waitForExistence(timeout: 5) else { return }
        firstLink.tap()

        let favButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'favorites'")
        ).firstMatch
        XCTAssertTrue(favButton.waitForExistence(timeout: 3))

        app.navigationBars.buttons.firstMatch.tap()
    }

    private func clearAllFavoritesIfNeeded(in app: XCUIApplication) {
        let clearButton = app.buttons
            .matching(NSPredicate(format: "label CONTAINS[c] 'clear'"))
            .firstMatch
        guard clearButton.waitForExistence(timeout: 1) else { return }
        clearButton.tap()

        let sheet = app.sheets["Remove all favorites?"]
        let confirm = sheet.waitForExistence(timeout: 2)
            ? sheet.buttons["Clear All"]
            : app.sheets.firstMatch.buttons["Clear All"]
        if confirm.waitForExistence(timeout: 2) {
            confirm.tap()
        }
    }
}

private struct NewsScreen {
    let app: XCUIApplication

    var navigationBar: XCUIElement { app.navigationBars.firstMatch }
    var searchField: XCUIElement { app.searchFields.firstMatch }
    var countryPickerButton: XCUIElement { app.buttons[A11yID.countryPickerButton] }
    var settingsButton: XCUIElement { app.buttons[A11yID.settingsButton] }
    var articleList: XCUIElement { app.scrollViews[A11yID.newsArticleList] }
}

private struct FavoritesScreen {
    let app: XCUIApplication

    @discardableResult
    func open() -> Self {
        app.tabBars.buttons.element(boundBy: 1).tap()
        return self
    }
}

private struct CountryPickerScreen {
    let app: XCUIApplication

    var navigationBar: XCUIElement { app.navigationBars["Select Country"] }
    var cancelButton: XCUIElement { app.buttons["Cancel country selection"] }
    func row(containing text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }
}

private struct SettingsScreen {
    let app: XCUIApplication

    var navigationBar: XCUIElement { app.navigationBars["Settings"] }
    var doneButton: XCUIElement { app.buttons["Close settings"] }
}

private enum A11yID {
    static let countryPickerButton = "country_picker_button"
    static let settingsButton = "settings_button"
    static let newsArticleList = "news_article_list"
    static let favoritesList = "favorites_list"
}

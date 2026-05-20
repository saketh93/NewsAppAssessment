import Combine
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var iconName: String {
        switch self {
        case .system: Constants.SFSymbols.circleHalfFilled
        case .light: Constants.SFSymbols.sunMaxFill
        case .dark: Constants.SFSymbols.moonFill
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    private static let key = "selected_theme"
    @Environment(\.colorScheme) var colorScheme

    var analytics: AnalyticsServiceProtocol?

    @Published var current: AppTheme {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: Self.key)
            guard oldValue != current else { return }
            AppLogger.info("Theme changed: \(oldValue.rawValue) -> \(current.rawValue)")
            analytics?.track(.themeChanged(to: current.rawValue))
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: Self.key) ?? ""
        
        if let savedTheme = AppTheme(rawValue: saved) {
            self.current = savedTheme
        } else {
            self.current = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
        }
    }
}

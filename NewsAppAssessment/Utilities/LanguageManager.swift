import Combine
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system = "System"
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:  return "System Default"
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french:  return "French"
        case .german:  return "German"
        }
    }

    var flagEmoji: String {
        switch self {
        case .system:  return "Globe"
        case .english: return "EN"
        case .spanish: return "ES"
        case .french:  return "FR"
        case .german:  return "DE"
        }
    }
}

@MainActor
final class LanguageManager: ObservableObject {
    private static let key = "selected_language"
    private static let appleLanguagesKey = "AppleLanguages"

    var analytics: AnalyticsServiceProtocol?

    @Published var current: AppLanguage {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: Self.key)
            applyLanguage()
            guard oldValue != current else { return }
            AppLogger.info("Language changed: \(oldValue.rawValue) -> \(current.rawValue)")
            analytics?.track(.languageChanged(to: current.rawValue))
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: Self.key) ?? ""
        self.current = AppLanguage(rawValue: saved) ?? .system
    }

    var bundle: Bundle {
        guard current != .system,
              let path = Bundle.main.path(forResource: current.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }

    func localize(_ key: String) -> String {
        NSLocalizedString(key, bundle: bundle, comment: "")
    }

    private func applyLanguage() {
        if current == .system {
            UserDefaults.standard.removeObject(forKey: Self.appleLanguagesKey)
        } else {
            UserDefaults.standard.set([current.rawValue], forKey: Self.appleLanguagesKey)
        }
    }
}

extension String {
    func localized(using manager: LanguageManager) -> String {
        NSLocalizedString(self, bundle: manager.bundle, comment: "")
    }
}

import SwiftUI

struct SettingsView: View {
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                AppearanceSection(themeManager: themeManager, languageManager: languageManager)
                LanguageSection(languageManager: languageManager)
            }
            .navigationTitle(languageManager.localize(Constants.LocalizationKeys.settingsTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(languageManager.localize(Constants.LocalizationKeys.done)) { dismiss() }
                        .accessibilityLabel("Close settings")
                }
            }
        }
        .modifier(SchemeOverride(scheme: themeManager.current.colorScheme))
    }
}

private struct SchemeOverride: ViewModifier {
    let scheme: ColorScheme?

    func body(content: Content) -> some View {
        if let scheme {
            content.colorScheme(scheme)
        } else {
            content
        }
    }
}

private struct AppearanceSection: View {
    @ObservedObject var themeManager: ThemeManager
    let languageManager: LanguageManager

    var body: some View {
        Section(languageManager.localize(Constants.LocalizationKeys.settingsAppearance)) {
            ForEach(AppTheme.allCases) { theme in
                ThemeRow(
                    theme: theme,
                    isSelected: themeManager.current == theme,
                    onTap: { themeManager.current = theme }
                )
            }
        }
    }
}

private struct LanguageSection: View {
    @ObservedObject var languageManager: LanguageManager

    var body: some View {
        Section(languageManager.localize(Constants.LocalizationKeys.settingsLanguage)) {
            ForEach(AppLanguage.allCases) { lang in
                LanguageRow(
                    language: lang,
                    isSelected: languageManager.current == lang,
                    onTap: { languageManager.current = lang }
                )
            }
        }
    }
}

private struct ThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            Image(systemName: theme.iconName)
                .foregroundColor(.accentColor)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(theme.rawValue)
            Spacer()
            if isSelected {
                Image(systemName: Constants.SFSymbols.checkmark)
                    .foregroundColor(.accentColor)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityLabel("\(theme.rawValue)\(isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isSelected ? "" : "Tap to apply this theme")
    }
}

private struct LanguageRow: View {
    let language: AppLanguage
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            Text(language.flagEmoji)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 28)
            Text(language.displayName)
            Spacer()
            if isSelected {
                Image(systemName: Constants.SFSymbols.checkmark)
                    .foregroundColor(.accentColor)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityLabel("\(language.displayName)\(isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isSelected ? "" : "Tap to switch to this language")
    }
}

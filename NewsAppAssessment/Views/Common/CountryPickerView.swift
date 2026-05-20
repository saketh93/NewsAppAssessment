import SwiftUI

struct CountryPickerView: View {
    @Binding var selectedCountry: Country
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager

    var body: some View {
        NavigationStack {
            List(Country.all) { country in
                CountryRowButton(
                    country: country,
                    isSelected: country.id == selectedCountry.id
                ) {
                    selectedCountry = country
                    dismiss()
                }
            }
            .navigationTitle(languageManager.localize(Constants.LocalizationKeys.selectCountry))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(languageManager.localize(Constants.LocalizationKeys.cancel)) { dismiss() }
                        .accessibilityLabel("Cancel country selection")
                }
            }
        }
    }
}

private struct CountryRowButton: View {
    let country: Country
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(country.flagEmoji)
                    .font(.title2)
                    .accessibilityHidden(true)
                Text(country.displayName)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: Constants.SFSymbols.checkmark)
                        .foregroundColor(.accentColor)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityLabel("\(country.displayName)\(isSelected ? ", selected" : "")")
        .accessibilityHint(isSelected ? "" : "Tap to select this country")
    }
}

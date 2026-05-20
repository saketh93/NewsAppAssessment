import SwiftUI

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let buttonText: String
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: systemImage)
                .font(.system(size: 56))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if let retry = retryAction {
                Button(buttonText,
                       action: retry)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier(Constants.A11yID.retryButton)
                    .accessibilityLabel("Retry loading")
                    .accessibilityHint("Tap to try again")
            }
            Spacer()
        }
        .accessibilityElement(children: .contain)
    }
}

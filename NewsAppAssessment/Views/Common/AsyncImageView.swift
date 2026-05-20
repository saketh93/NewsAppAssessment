import SwiftUI

struct AsyncImageView: View {
    let urlString: String?

    var body: some View {
        Group {
            if let urlString, !urlString.isEmpty, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .foregroundColor(Color(.systemGray5))
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        imagePlaceholder
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                imagePlaceholder
            }
        }
        .clipped()
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .foregroundColor(Color(.systemGray5))
            .overlay(
                Image(systemName: Constants.SFSymbols.photo)
                    .font(.title2)
                    .foregroundColor(.secondary)
            )
    }
}

import Foundation

struct Country: Identifiable, Hashable, Codable {
    let id: String
    let displayName: String
    let flagEmoji: String

    static let all: [Country] = [
        Country(id: "us", displayName: "United States", flagEmoji: "🇺🇸"),
        Country(id: "gb", displayName: "United Kingdom", flagEmoji: "🇬🇧"),
        Country(id: "in", displayName: "India", flagEmoji: "🇮🇳"),
        Country(id: "au", displayName: "Australia", flagEmoji: "🇦🇺"),
        Country(id: "ca", displayName: "Canada", flagEmoji: "🇨🇦"),
        Country(id: "de", displayName: "Germany", flagEmoji: "🇩🇪"),
        Country(id: "fr", displayName: "France", flagEmoji: "🇫🇷"),
        Country(id: "jp", displayName: "Japan", flagEmoji: "🇯🇵"),
        Country(id: "ae", displayName: "UAE", flagEmoji: "🇦🇪"),
        Country(id: "sg", displayName: "Singapore", flagEmoji: "🇸🇬")
    ]

    static let `default` = Country.all[0]
}

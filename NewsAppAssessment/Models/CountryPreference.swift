import Foundation
import SwiftData

@Model
final class CountryPreference {
    var countryID: String

    init(countryID: String) {
        self.countryID = countryID
    }
}

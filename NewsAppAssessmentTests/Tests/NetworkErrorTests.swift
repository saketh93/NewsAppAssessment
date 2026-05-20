import Testing
@testable import NewsAppAssessment
import Foundation

struct NetworkErrorTests {
    @Test(
        "errorDescription is non-empty for every case",
        arguments: [
            NetworkError.invalidURL,
            NetworkError.noData,
            NetworkError.unauthorized,
            NetworkError.noInternet,
            NetworkError.serverError(503),
            NetworkError.decodingFailed("parse fail"),
            NetworkError.unknown("custom msg")
        ]
    )
    func errorDescription_isNonEmpty(error: NetworkError) {
        let description = error.localizedDescription(manager: LanguageManager())
        #expect(!description.isEmpty)
    }

    @Test func unknownError_descriptionPassesThroughMessage() {
        let error = NetworkError.unknown("custom msg")
        let errorDescription = error.localizedDescription(manager: LanguageManager())
        #expect(errorDescription == "custom msg")
    }

    @Test(
        "Equal errors match",
        arguments: [
            (NetworkError.invalidURL,        NetworkError.invalidURL),
            (NetworkError.noInternet,        NetworkError.noInternet),
            (NetworkError.unauthorized,      NetworkError.unauthorized),
            (NetworkError.serverError(400),  NetworkError.serverError(400))
        ]
    )
    func errorEquality(pair: (NetworkError, NetworkError)) {
        #expect(pair.0 == pair.1)
    }

    @Test func serverError_differentCodes_areNotEqual() {
        #expect(NetworkError.serverError(400) != NetworkError.serverError(500))
    }
}

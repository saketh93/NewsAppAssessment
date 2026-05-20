import Foundation

@MainActor
enum NetworkError: Error, Equatable {
    case invalidURL
    case noData
    case decodingFailed(String)
    case serverError(Int)
    case unauthorized
    case noInternet
    case unknown(String)

    func localizedDescription(manager: LanguageManager) -> String {
        switch self {
        case .invalidURL: manager.localize("error_invalid_url")
        case .noData: manager.localize("error_no_data")
        case .decodingFailed: manager.localize("error_decoding")
        case .serverError(let code): String(format: manager.localize("error_server"), code)
        case .unauthorized: manager.localize("error_unauthorized")
        case .noInternet: manager.localize("error_no_internet")
        case .unknown(let msg): msg
        }
    }
}

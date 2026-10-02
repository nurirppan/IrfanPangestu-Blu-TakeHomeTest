import Foundation

/// Builds search URLs. `URLComponents.queryItems` leaves `+` unescaped, and the server reads it as a space.
enum ItunesSearchEndpointType {
    static let limit = 50

    private static let unreservedCharacters = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )

    static func url(term: String) -> URL? {
        guard let encodedTerm = term.addingPercentEncoding(withAllowedCharacters: unreservedCharacters) else {
            return nil
        }
        return URL(string: "https://itunes.apple.com/search?term=\(encodedTerm)&media=music&entity=song&limit=\(limit)")
    }
}

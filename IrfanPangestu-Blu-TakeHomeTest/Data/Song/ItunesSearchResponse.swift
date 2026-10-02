/// Mirrors the iTunes JSON. Every field is optional so one incomplete item can't fail the whole response.
struct ItunesSearchResponse: Decodable, Sendable {
    let resultCount: Int?
    let results: [ItunesTrackResponse]?
}

/// Only the six fields the app shows or plays; `Decodable` skips the other 28.
struct ItunesTrackResponse: Decodable, Sendable {
    let trackId: Int?
    let trackName: String?
    let artistName: String?
    let collectionName: String?
    let artworkUrl100: String?
    let previewUrl: String?
}

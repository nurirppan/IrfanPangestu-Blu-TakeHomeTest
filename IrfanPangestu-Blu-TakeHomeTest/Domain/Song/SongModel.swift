import Foundation

/// A playable song: what the list shows and what the player streams.
struct SongModel: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let artist: String
    let album: String
    let artworkURL: URL?
    let previewURL: URL
}

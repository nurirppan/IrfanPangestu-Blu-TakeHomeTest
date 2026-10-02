import Foundation

/// iTunes-backed catalog: maps the response to `SongModel` and every failure to `AppErrorType`.
final class SongRepositoryImpl: SongRepository {
    private let apiService: any ItunesAPIService

    /// The app chooses the session; the API service behind it stays inside the data layer.
    convenience init(session: URLSession) {
        self.init(apiService: URLSessionItunesAPIService(session: session))
    }

    init(apiService: any ItunesAPIService) {
        self.apiService = apiService
    }

    func searchSongs(term: String) async throws -> [SongModel] {
        let response: ItunesSearchResponse
        do {
            response = try await apiService.search(term: term)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw ErrorMapperType.map(error)
        }
        return Self.songs(from: response.results ?? [])
    }

    /// Drops items with nothing to play, and repeated track IDs, which would give the list two rows for one song.
    static func songs(from tracks: [ItunesTrackResponse]) -> [SongModel] {
        var seenIDs = Set<Int>()
        return tracks.compactMap { track in
            guard let id = track.trackId,
                  let previewURL = track.previewUrl.flatMap({ URL(string: $0) }),
                  seenIDs.insert(id).inserted else {
                return nil
            }
            return SongModel(
                id: id,
                title: track.trackName ?? String(localized: "Unknown title"),
                artist: track.artistName ?? String(localized: "Unknown artist"),
                album: track.collectionName ?? String(localized: "Unknown album"),
                artworkURL: artworkURL(from: track.artworkUrl100),
                previewURL: previewURL
            )
        }
    }

    /// iTunes serves any artwork size through the URL; 200 px fits a list row on a 3x screen.
    static func artworkURL(from rawValue: String?) -> URL? {
        rawValue.flatMap { URL(string: $0.replacingOccurrences(of: "100x100bb", with: "200x200bb")) }
    }
}

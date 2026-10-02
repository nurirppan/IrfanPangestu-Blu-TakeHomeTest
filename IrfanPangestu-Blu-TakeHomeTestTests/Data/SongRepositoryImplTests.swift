import Foundation
@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

struct SongRepositoryImplTests {
    @Test("Maps a real response to songs with larger artwork")
    func mapsSongs() async throws {
        let repository = try Self.repository(returning: "search_songs")

        let songs = try await repository.searchSongs(term: "coldplay")

        #expect(songs.count == 5)
        let yellow = try #require(songs.first)
        #expect(yellow.id == 1_122_782_283)
        #expect(yellow.title == "Yellow")
        #expect(yellow.artist == "Coldplay")
        #expect(yellow.album == "Parachutes")
        #expect(yellow.previewURL.scheme == "https")
        #expect(yellow.artworkURL?.absoluteString.hasSuffix("/200x200bb.jpg") == true)
    }

    @Test("Drops items without a preview and repeated track IDs")
    func dropsUnplayableAndDuplicateItems() async throws {
        let repository = try Self.repository(returning: "search_songs_edge")

        let songs = try await repository.searchSongs(term: "coldplay")

        #expect(songs.map(\.id) == [1_122_782_283, 829_910_927, 1_122_776_155, 1_122_782_281])
    }

    @Test("Turns transport failures into AppErrorType")
    func mapsErrors() async {
        let repository = SongRepositoryImpl(apiService: StubItunesAPIService(result: .failure(URLError(.notConnectedToInternet))))

        await #expect(throws: AppErrorType.noConnection) {
            try await repository.searchSongs(term: "coldplay")
        }
    }

    @Test("Reports a cancelled request as cancellation, not as an error to show")
    func mapsCancellation() async {
        let repository = SongRepositoryImpl(apiService: StubItunesAPIService(result: .failure(URLError(.cancelled))))

        await #expect(throws: CancellationError.self) {
            try await repository.searchSongs(term: "coldplay")
        }
    }

    private static func repository(returning fixture: String) throws -> SongRepositoryImpl {
        let response = try JSONDecoder().decode(ItunesSearchResponse.self, from: FixtureType.data(fixture))
        return SongRepositoryImpl(apiService: StubItunesAPIService(result: .success(response)))
    }
}

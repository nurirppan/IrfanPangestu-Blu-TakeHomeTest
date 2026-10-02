import Foundation
@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

struct ItunesSearchResponseTests {
    @Test("Decodes the mapped fields from a real response")
    func decodesSongs() throws {
        let response = try JSONDecoder().decode(ItunesSearchResponse.self, from: FixtureType.data("search_songs"))

        #expect(response.resultCount == 5)
        let yellow = try #require(response.results?.first)
        #expect(yellow.trackId == 1_122_782_283)
        #expect(yellow.trackName == "Yellow")
        #expect(yellow.artistName == "Coldplay")
        #expect(yellow.collectionName == "Parachutes")
        #expect(yellow.artworkUrl100?.hasSuffix("100x100bb.jpg") == true)
        #expect(yellow.previewUrl?.hasPrefix("https://") == true)
    }

    @Test("Decodes an empty result set")
    func decodesEmptyResults() throws {
        let response = try JSONDecoder().decode(ItunesSearchResponse.self, from: FixtureType.data("search_empty"))

        #expect(response.resultCount == 0)
        #expect(response.results?.isEmpty == true)
    }
}

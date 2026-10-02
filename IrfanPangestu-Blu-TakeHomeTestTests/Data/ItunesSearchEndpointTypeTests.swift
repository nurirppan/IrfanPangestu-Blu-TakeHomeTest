import Foundation
@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

struct ItunesSearchEndpointTypeTests {
    @Test("Asks for songs only, 50 at a time")
    func buildsSongSearchURL() throws {
        let url = try #require(ItunesSearchEndpointType.url(term: "coldplay"))

        #expect(url.absoluteString == "https://itunes.apple.com/search?term=coldplay&media=music&entity=song&limit=50")
    }

    @Test(
        "Encodes characters the server would otherwise misread",
        arguments: zip(
            ["Romeo + Juliet", "Fast & Furious", "AC/DC", "Beyoncé"],
            ["term=Romeo%20%2B%20Juliet&", "term=Fast%20%26%20Furious&", "term=AC%2FDC&", "term=Beyonc%C3%A9&"]
        )
    )
    func encodesTerm(term: String, expectedQuery: String) throws {
        let url = try #require(ItunesSearchEndpointType.url(term: term))

        #expect(url.absoluteString.contains(expectedQuery))
    }
}

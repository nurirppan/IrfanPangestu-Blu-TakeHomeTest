import Foundation
@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

struct ErrorMapperTypeTests {
    @Test(
        "Maps connectivity failures to noConnection",
        arguments: [URLError.Code.notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff]
    )
    func mapsNoConnection(code: URLError.Code) {
        #expect(ErrorMapperType.map(URLError(code)) == .noConnection)
    }

    @Test("Maps a timeout")
    func mapsTimeout() {
        #expect(ErrorMapperType.map(URLError(.timedOut)) == .timeout)
    }

    @Test("Keeps the status code of a server error")
    func mapsHTTPStatus() {
        #expect(ErrorMapperType.map(HTTPStatusError(statusCode: 503)) == .server(code: 503))
    }

    @Test("Maps unreadable data to invalidData")
    func mapsDecodingError() {
        let context = DecodingError.Context(codingPath: [], debugDescription: "Unexpected body")

        #expect(ErrorMapperType.map(DecodingError.dataCorrupted(context)) == .invalidData)
        #expect(ErrorMapperType.map(URLError(.cannotParseResponse)) == .invalidData)
    }

    @Test("Passes an AppErrorType through unchanged")
    func passesAppErrorThrough() {
        #expect(ErrorMapperType.map(AppErrorType.playbackFailed) == .playbackFailed)
    }

    @Test("Falls back to unknown")
    func mapsUnknown() {
        #expect(ErrorMapperType.map(CocoaError(.fileNoSuchFile)) == .unknown)
        #expect(ErrorMapperType.map(URLError(.badURL)) == .unknown)
    }
}

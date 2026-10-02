import Foundation
@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

/// Serialized because every test swaps the shared `StubURLProtocol.handler`.
@Suite(.serialized)
struct URLSessionItunesAPIServiceTests {
    private let service = URLSessionItunesAPIService(session: StubURLProtocol.makeSession())

    @Test("Requests songs for the encoded term and decodes the response")
    func decodesSuccessfulResponse() async throws {
        let body = try FixtureType.data("search_songs")
        let recorder = RequestRecorder()
        StubURLProtocol.handler = { request in
            recorder.record(request)
            return (try StubURLProtocol.response(for: request, statusCode: 200), body)
        }

        let response = try await service.search(term: "Romeo + Juliet")

        #expect(response.resultCount == 5)
        let url = try #require(recorder.lastURL)
        #expect(url.absoluteString.contains("term=Romeo%20%2B%20Juliet&media=music&entity=song&limit=50"))
    }

    @Test("Throws the status code of a non-2xx response")
    func throwsHTTPStatus() async throws {
        let body = try FixtureType.data("search_error_400")
        StubURLProtocol.handler = { request in
            (try StubURLProtocol.response(for: request, statusCode: 400), body)
        }

        await #expect(throws: HTTPStatusError(statusCode: 400)) {
            try await service.search(term: "coldplay")
        }
    }

    @Test("Passes transport errors through untouched")
    func passesTransportErrors() async throws {
        StubURLProtocol.handler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await service.search(term: "coldplay")
            Issue.record("Expected a transport error")
        } catch let error as URLError {
            #expect(error.code == .notConnectedToInternet)
        }
    }

    @Test("Fails to decode a body that isn't the expected JSON")
    func throwsOnUnexpectedBody() async throws {
        StubURLProtocol.handler = { request in
            (try StubURLProtocol.response(for: request, statusCode: 200), Data("<html>".utf8))
        }

        await #expect(throws: DecodingError.self) {
            try await service.search(term: "coldplay")
        }
    }
}

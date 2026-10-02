import Foundation

/// Transport only: build the URL, send, check the status, decode. It knows nothing about songs or on-screen errors.
protocol ItunesAPIService: Sendable {
    func search(term: String) async throws -> ItunesSearchResponse
}

/// A non-2xx response; `ErrorMapperType` turns it into `AppErrorType.server`.
struct HTTPStatusError: Error, Equatable {
    let statusCode: Int
}

struct URLSessionItunesAPIService: ItunesAPIService {
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func search(term: String) async throws -> ItunesSearchResponse {
        guard let url = ItunesSearchEndpointType.url(term: term) else {
            throw URLError(.badURL)
        }
        let (data, response) = try await session.data(from: url)
        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
            throw HTTPStatusError(statusCode: httpResponse.statusCode)
        }
        return try JSONDecoder().decode(ItunesSearchResponse.self, from: data)
    }
}

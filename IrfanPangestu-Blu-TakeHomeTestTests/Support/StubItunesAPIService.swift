@testable import IrfanPangestu_Blu_TakeHomeTest

/// Returns a canned result, so repository tests run without any networking.
struct StubItunesAPIService: ItunesAPIService {
    let result: Result<ItunesSearchResponse, any Error>

    func search(term: String) async throws -> ItunesSearchResponse {
        try result.get()
    }
}

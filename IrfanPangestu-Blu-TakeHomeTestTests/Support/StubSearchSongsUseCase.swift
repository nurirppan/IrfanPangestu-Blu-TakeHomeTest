@testable import IrfanPangestu_Blu_TakeHomeTest

/// Answers searches from a script, one result per call; the last result repeats.
actor StubSearchSongsUseCase: SearchSongsUseCase {
    private var results: [Result<[SongModel], AppErrorType>]

    init(results: [Result<[SongModel], AppErrorType>]) {
        self.results = results
    }

    func search(term: String) async throws -> [SongModel] {
        let result = results.count > 1 ? results.removeFirst() : results[0]
        return try result.get()
    }
}

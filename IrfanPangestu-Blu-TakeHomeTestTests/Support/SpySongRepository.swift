@testable import IrfanPangestu_Blu_TakeHomeTest

/// Records every term it receives and answers with a canned result.
actor SpySongRepository: SongRepository {
    private let result: Result<[SongModel], AppErrorType>
    private(set) var receivedTerms: [String] = []

    init(result: Result<[SongModel], AppErrorType>) {
        self.result = result
    }

    func searchSongs(term: String) async throws -> [SongModel] {
        receivedTerms.append(term)
        return try result.get()
    }
}

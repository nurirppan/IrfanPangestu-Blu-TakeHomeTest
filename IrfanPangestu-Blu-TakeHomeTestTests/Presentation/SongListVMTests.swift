@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

@MainActor
struct SongListVMTests {
    @Test("Starts idle")
    func startsIdle() {
        let viewModel = makeViewModel(query: "", results: .success([]))

        #expect(viewModel.state == .idle)
    }

    @Test("Shows the songs it found")
    func showsSongs() async {
        let songs = [SongModel.sample(id: 1), .sample(id: 2)]
        let viewModel = makeViewModel(query: "coldplay", results: .success(songs))

        await viewModel.search()

        #expect(viewModel.state == .loaded(songs))
    }

    @Test("Names the trimmed term when nothing is found")
    func showsEmptyState() async {
        let viewModel = makeViewModel(query: "  qzxwvkjhqz ", results: .success([]))

        await viewModel.search()

        #expect(viewModel.state == .empty(term: "qzxwvkjhqz"))
    }

    @Test("Shows the error it got")
    func showsFailure() async {
        let viewModel = makeViewModel(query: "coldplay", results: .failure(.noConnection))

        await viewModel.search()

        #expect(viewModel.state == .failed(.noConnection))
    }

    @Test("Ignores a blank query")
    func ignoresBlankQuery() async {
        let viewModel = makeViewModel(query: "   ", results: .success([.sample(id: 1)]))

        await viewModel.search()

        #expect(viewModel.state == .idle)
    }

    @Test("Retry runs the failed search again")
    func retriesFailedSearch() async {
        let songs = [SongModel.sample(id: 1)]
        let viewModel = makeViewModel(query: "coldplay", results: .failure(.timeout), .success(songs))

        await viewModel.search()
        #expect(viewModel.state == .failed(.timeout))

        await viewModel.retry()
        #expect(viewModel.state == .loaded(songs))
    }

    @Test("A new search cancels a retry still waiting, so its late answer can't replace the new list")
    func newSearchCancelsRetry() async throws {
        let viewModel = SongListVM(searchUseCase: SlowRetrySearchSongsUseCase())
        viewModel.query = "coldplay"
        await viewModel.search()

        viewModel.submitRetry()
        viewModel.query = "adele"
        viewModel.submitSearch()
        try await Task.sleep(for: .milliseconds(600))

        #expect(viewModel.state == .loaded([.sample(id: 2)]))
    }

    private func makeViewModel(query: String, results: Result<[SongModel], AppErrorType>...) -> SongListVM {
        let searchUseCase = StubSearchSongsUseCase(results: results)
        let viewModel = SongListVM(searchUseCase: searchUseCase)
        viewModel.query = query
        return viewModel
    }
}

/// Fails "coldplay" once, then answers it slowly, and answers "adele" at once, so a new search can overtake a retry.
private actor SlowRetrySearchSongsUseCase: SearchSongsUseCase {
    private var hasFailed = false

    func search(term: String) async throws -> [SongModel] {
        if term == "adele" {
            return [.sample(id: 2)]
        }
        guard hasFailed else {
            hasFailed = true
            throw AppErrorType.timeout
        }
        try await Task.sleep(for: .milliseconds(300))
        return [.sample(id: 1)]
    }
}

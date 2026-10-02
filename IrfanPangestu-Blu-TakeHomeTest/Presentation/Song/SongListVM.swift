import Combine
import FactoryKit
import Foundation

@MainActor
final class SongListVM: ObservableObject, ErrorHandling {
    @Published var query = ""
    @Published private(set) var state = SongListStateType.idle

    private let searchUseCase: any SearchSongsUseCase
    private var searchTask: Task<Void, Never>?
    private var retryOperation: (@MainActor () async -> Void)?

    init(searchUseCase: any SearchSongsUseCase = Container.shared.searchSongsUseCase()) {
        self.searchUseCase = searchUseCase
    }

    /// Called from the keyboard's Search button; a newer search cancels the one still running.
    func submitSearch() {
        replaceRunningSearch { [weak self] in
            await self?.search()
        }
    }

    /// Called from the Retry button. A retry is a search too, so a newer search cancels it and its late answer is dropped.
    func submitRetry() {
        replaceRunningSearch { [weak self] in
            await self?.retry()
        }
    }

    /// Runs the operation that failed last, again.
    func retry() async {
        guard let retryOperation else {
            return
        }
        state = .loading
        await retryOperation()
    }

    func handle(_ error: AppErrorType, retry: @escaping @MainActor () async -> Void) {
        state = .failed(error)
        retryOperation = retry
    }

    func search() async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            return
        }
        state = .loading
        await performTask { [weak self] in
            guard let self else {
                return
            }
            let songs = try await searchUseCase.search(term: term)
            guard !Task.isCancelled else {
                return
            }
            state = songs.isEmpty ? .empty(term: term) : .loaded(songs)
        }
    }

    private func replaceRunningSearch(_ work: @escaping @MainActor () async -> Void) {
        searchTask?.cancel()
        searchTask = Task { await work() }
    }
}

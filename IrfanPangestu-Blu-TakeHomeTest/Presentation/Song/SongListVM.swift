import Combine
import FactoryKit
import Foundation

@MainActor
final class SongListVM: ObservableObject, ErrorHandling {
    @Published var query = ""
    @Published private(set) var state = SongListStateType.idle
    /// Follows the track ID, not the row, so the mark stays right after a new search.
    @Published private(set) var playingSongID: Int?
    /// Whether that song plays or is paused; the mark moves only while it plays.
    @Published private(set) var isPlaying = false

    private let searchUseCase: any SearchSongsUseCase
    private let playerUseCase: any MusicPlayerUseCase
    private var searchTask: Task<Void, Never>?
    private var retryOperation: (@MainActor () async -> Void)?
    private var cancellables = Set<AnyCancellable>()

    init(
        searchUseCase: any SearchSongsUseCase = Container.shared.searchSongsUseCase(),
        playerUseCase: any MusicPlayerUseCase = Container.shared.musicPlayerUseCase()
    ) {
        self.searchUseCase = searchUseCase
        self.playerUseCase = playerUseCase
        playerUseCase.statePublisher
            .map { ($0.currentSong?.id, $0.isPlaying) }
            .removeDuplicates { $0 == $1 }
            .sink { [weak self] songID, isPlaying in
                self?.playingSongID = songID
                self?.isPlaying = isPlaying
            }
            .store(in: &cancellables)
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

    /// The tapped song plays, and the list on screen becomes the queue.
    func didSelect(_ song: SongModel) {
        guard case let .loaded(songs) = state, let index = songs.firstIndex(of: song) else {
            return
        }
        playerUseCase.play(songs: songs, startAt: index)
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

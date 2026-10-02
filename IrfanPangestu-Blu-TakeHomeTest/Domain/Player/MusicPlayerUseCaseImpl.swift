import Combine
import Foundation

@MainActor
final class MusicPlayerUseCaseImpl: MusicPlayerUseCase {
    private(set) var state = PlaybackStateModel.idle {
        didSet {
            if state != oldValue {
                subject.send(state)
            }
        }
    }

    var statePublisher: AnyPublisher<PlaybackStateModel, Never> {
        subject.eraseToAnyPublisher()
    }

    private let repository: any PlayerRepository
    private let subject = CurrentValueSubject<PlaybackStateModel, Never>(.idle)
    private var queue = PlaybackQueue()

    init(repository: any PlayerRepository) {
        self.repository = repository
        repository.onEvent = { [weak self] event in
            self?.handle(event)
        }
    }

    /// Tapping the song that's already playing pauses or resumes it.
    func play(songs: [SongModel], startAt index: Int) {
        let isCurrentSong = songs.indices.contains(index) && songs[index] == state.currentSong
        guard let song = queue.select(songs: songs, at: index) else {
            return
        }
        guard isCurrentSong else {
            start(song)
            return
        }
        update {
            $0.hasNext = queue.hasNext
            $0.hasPrevious = queue.hasPrevious
        }
        togglePlayPause()
    }

    func togglePlayPause() {
        guard state.currentSong != nil else {
            return
        }
        if state.isPlaying {
            repository.pause()
            update {
                $0.isPlaying = false
                $0.isBuffering = false
            }
        } else {
            repository.resume()
            update { $0.isPlaying = true }
        }
    }

    func next() {
        guard let song = queue.next() else {
            return
        }
        start(song)
    }

    /// On the first song there is nothing before it, so previous restarts it instead of doing nothing.
    func previous() {
        if let song = queue.previous() {
            start(song)
        } else {
            seek(to: 0)
        }
    }

    func seek(to position: TimeInterval) {
        guard state.currentSong != nil else {
            return
        }
        repository.seek(to: position)
        update { $0.position = position }
    }

    private func start(_ song: SongModel) {
        var newState = PlaybackStateModel.idle
        newState.currentSong = song
        newState.isPlaying = true
        newState.isBuffering = true
        newState.hasNext = queue.hasNext
        newState.hasPrevious = queue.hasPrevious
        state = newState
        repository.play(url: song.previewURL)
    }

    private func handle(_ event: PlayerEventType) {
        switch event {
        case let .progress(position, duration):
            update {
                $0.position = position
                $0.duration = duration
            }
        case let .status(isPlaying, isBuffering):
            update {
                $0.isPlaying = isPlaying
                $0.isBuffering = isBuffering
            }
        case .finished, .failed:
            break
        }
    }

    /// Applies several field changes as one state change, so subscribers re-render once.
    private func update(_ change: (inout PlaybackStateModel) -> Void) {
        var newState = state
        change(&newState)
        state = newState
    }
}

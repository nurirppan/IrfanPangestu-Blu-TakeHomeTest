import Combine

/// One more subscriber to the player's state, like the two view models: the player never learns the lock screen exists.
@MainActor
final class NowPlayingUseCaseImpl: NowPlayingUseCase {
    private let playerUseCase: any MusicPlayerUseCase
    private let repository: any NowPlayingRepository
    private var subscription: AnyCancellable?

    init(playerUseCase: any MusicPlayerUseCase, repository: any NowPlayingRepository) {
        self.playerUseCase = playerUseCase
        self.repository = repository
    }

    func start() {
        repository.onCommand = { [weak self] command in
            self?.handle(command)
        }
        subscription = playerUseCase.statePublisher.sink { [weak self] state in
            self?.repository.show(state)
        }
    }

    /// Headphones and some surfaces send play and pause separately, so each acts only when it changes something.
    private func handle(_ command: RemoteCommandType) {
        switch command {
        case .play:
            if !playerUseCase.state.isPlaying {
                playerUseCase.togglePlayPause()
            }
        case .pause:
            if playerUseCase.state.isPlaying {
                playerUseCase.togglePlayPause()
            }
        case .togglePlayPause:
            playerUseCase.togglePlayPause()
        case .next:
            playerUseCase.next()
        case .previous:
            playerUseCase.previous()
        case .seek(let position):
            playerUseCase.seek(to: position)
        }
    }
}

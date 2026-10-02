@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

/// Runs against the real player use case, so the buttons are checked by what the player ends up doing.
@MainActor
struct NowPlayingUseCaseTests {
    private let songs = [SongModel.sample(id: 1), .sample(id: 2), .sample(id: 3)]
    private let player = FakePlayerRepository()
    private let lockScreen = FakeNowPlayingRepository()
    private let playerUseCase: MusicPlayerUseCaseImpl
    private let useCase: NowPlayingUseCaseImpl

    init() {
        playerUseCase = MusicPlayerUseCaseImpl(repository: player)
        useCase = NowPlayingUseCaseImpl(playerUseCase: playerUseCase, repository: lockScreen)
        useCase.start()
    }

    @Test("Shows the player's state at once, then every change")
    func followsThePlayer() {
        #expect(lockScreen.shownStates == [.idle])

        playerUseCase.play(songs: songs, startAt: 1)

        #expect(lockScreen.shownStates.last?.currentSong == songs[1])
    }

    @Test("Lock-screen buttons drive the player")
    func buttonsDriveThePlayer() {
        playerUseCase.play(songs: songs, startAt: 0)

        lockScreen.press(.next)
        #expect(playerUseCase.state.currentSong == songs[1])
        lockScreen.press(.previous)
        #expect(playerUseCase.state.currentSong == songs[0])
        lockScreen.press(.seek(position: 12))
        #expect(player.seekPositions == [12])
        lockScreen.press(.togglePlayPause)
        #expect(!playerUseCase.state.isPlaying)
    }

    @Test("Play and pause act only when they change something")
    func playAndPauseOnlyChangeWhatNeedsChanging() {
        playerUseCase.play(songs: songs, startAt: 0)

        lockScreen.press(.play)
        #expect(player.pauseCount == 0)
        lockScreen.press(.pause)
        lockScreen.press(.pause)
        #expect(player.pauseCount == 1)
        lockScreen.press(.play)
        #expect(player.resumeCount == 1)
        #expect(playerUseCase.state.isPlaying)
    }
}

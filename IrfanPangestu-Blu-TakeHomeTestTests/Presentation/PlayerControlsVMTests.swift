@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

@MainActor
struct PlayerControlsVMTests {
    private let useCase = FakeMusicPlayerUseCase()
    private let viewModel: PlayerControlsVM

    init() {
        viewModel = PlayerControlsVM(playerUseCase: useCase)
    }

    @Test("Stays hidden until a song is chosen")
    func hiddenWithoutSong() {
        #expect(!viewModel.isVisible)

        useCase.state = Self.state(song: .sample(id: 1, title: "Yellow"))

        #expect(viewModel.isVisible)
        #expect(viewModel.title == "Yellow")
        #expect(viewModel.artist == "Coldplay")
    }

    @Test("The play button shows a spinner while buffering, then pause or play")
    func playButtonFollowsPlayback() {
        var state = Self.state(song: .sample(id: 1))
        state.isBuffering = true
        useCase.state = state
        #expect(viewModel.isBuffering)

        state.isBuffering = false
        useCase.state = state
        #expect(!viewModel.isBuffering)
        #expect(viewModel.playButtonSymbol == "pause.fill")

        state.isPlaying = false
        useCase.state = state
        #expect(viewModel.playButtonSymbol == "play.fill")
    }

    @Test("Next turns off on the last song, previous stays on")
    func navigationAvailability() {
        var state = Self.state(song: .sample(id: 3))
        state.hasNext = false
        useCase.state = state

        #expect(!viewModel.isNextEnabled)
        #expect(viewModel.isPreviousEnabled)
    }

    @Test("The slider waits for the duration, then follows the position")
    func sliderFollowsPlayback() {
        useCase.state = Self.state(song: .sample(id: 1))
        #expect(!viewModel.isSliderEnabled)

        var state = useCase.state
        state.duration = 30
        state.position = 12
        useCase.state = state

        #expect(viewModel.isSliderEnabled)
        #expect(viewModel.sliderRange == 0...30)
        #expect(viewModel.sliderPosition == 12)
        #expect(viewModel.elapsedText == "0:12")
        #expect(viewModel.durationText == "0:30")
    }

    @Test("Shows a playback error as text")
    func showsPlaybackError() {
        var state = Self.state(song: .sample(id: 1))
        state.error = .playbackFailed
        useCase.state = state

        #expect(viewModel.errorMessage == "This song can't be played")
    }

    @Test("The buttons go straight to the player")
    func forwardsButtons() {
        viewModel.previous()
        viewModel.togglePlayPause()
        viewModel.next()

        #expect(useCase.commands == ["previous", "toggle", "next"])
    }

    private static func state(song: SongModel) -> PlaybackStateModel {
        var state = PlaybackStateModel.idle
        state.currentSong = song
        state.isPlaying = true
        state.hasNext = true
        return state
    }
}

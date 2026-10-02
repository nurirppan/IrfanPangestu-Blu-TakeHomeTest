import Combine
@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

@MainActor
struct MusicPlayerUseCaseTests {
    private let songs = [SongModel.sample(id: 1), .sample(id: 2), .sample(id: 3)]
    private let repository = FakePlayerRepository()
    private let useCase: MusicPlayerUseCaseImpl

    init() {
        useCase = MusicPlayerUseCaseImpl(repository: repository)
    }

    @Test("Plays the chosen song from the list")
    func playsChosenSong() {
        useCase.play(songs: songs, startAt: 1)

        #expect(repository.playedURLs == [songs[1].previewURL])
        #expect(useCase.state.currentSong == songs[1])
        #expect(useCase.state.isPlaying)
        #expect(useCase.state.isBuffering)
        #expect(useCase.state.hasNext)
        #expect(useCase.state.hasPrevious)
    }

    @Test("Toggle pauses, then resumes from the same spot")
    func togglesPlayback() {
        useCase.play(songs: songs, startAt: 0)

        useCase.togglePlayPause()
        #expect(repository.pauseCount == 1)
        #expect(!useCase.state.isPlaying)

        useCase.togglePlayPause()
        #expect(repository.resumeCount == 1)
        #expect(useCase.state.isPlaying)
    }

    @Test("Toggle does nothing before a song is chosen")
    func ignoresToggleWithoutSong() {
        useCase.togglePlayPause()

        #expect(repository.pauseCount == 0)
        #expect(repository.resumeCount == 0)
    }

    @Test("Next and previous move through the list")
    func walksTheList() {
        useCase.play(songs: songs, startAt: 0)

        useCase.next()
        #expect(useCase.state.currentSong == songs[1])
        useCase.previous()
        #expect(useCase.state.currentSong == songs[0])
        #expect(repository.playedURLs == [songs[0].previewURL, songs[1].previewURL, songs[0].previewURL])
    }

    @Test("Next does nothing on the last song")
    func ignoresNextOnLastSong() {
        useCase.play(songs: songs, startAt: 2)

        useCase.next()

        #expect(repository.playedURLs.count == 1)
        #expect(!useCase.state.hasNext)
    }

    @Test("Previous on the first song restarts it")
    func restartsFirstSong() {
        useCase.play(songs: songs, startAt: 0)

        useCase.previous()

        #expect(repository.seekPositions == [0])
        #expect(useCase.state.currentSong == songs[0])
    }

    @Test("Seek moves the player and the state")
    func seeks() {
        useCase.play(songs: songs, startAt: 0)

        useCase.seek(to: 12)

        #expect(repository.seekPositions == [12])
        #expect(useCase.state.position == 12)
    }

    @Test("Player events update the state")
    func appliesPlayerEvents() {
        useCase.play(songs: songs, startAt: 0)

        repository.send(.progress(position: 5, duration: 30))
        repository.send(.status(isPlaying: true, isBuffering: false))

        #expect(useCase.state.position == 5)
        #expect(useCase.state.duration == 30)
        #expect(!useCase.state.isBuffering)
    }

    @Test("Every subscriber sees the same state")
    func publishesToEverySubscriber() {
        var first: PlaybackStateModel?
        var second: PlaybackStateModel?
        let firstSubscription = useCase.statePublisher.sink { first = $0 }
        let secondSubscription = useCase.statePublisher.sink { second = $0 }

        useCase.play(songs: songs, startAt: 1)

        #expect(first?.currentSong == songs[1])
        #expect(second?.currentSong == songs[1])
        firstSubscription.cancel()
        secondSubscription.cancel()
    }
}

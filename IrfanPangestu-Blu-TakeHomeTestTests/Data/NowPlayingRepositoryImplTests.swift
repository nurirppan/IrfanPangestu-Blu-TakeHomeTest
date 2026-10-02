import Foundation
@testable import IrfanPangestu_Blu_TakeHomeTest
import MediaPlayer
import Testing

/// Serialized because the system's Now Playing info is one global per process.
@MainActor
@Suite(.serialized)
struct NowPlayingRepositoryImplTests {
    private let playing: PlaybackStateModel = {
        var state = PlaybackStateModel.idle
        state.currentSong = SongModel(
            id: 1,
            title: "Yellow",
            artist: "Coldplay",
            album: "Parachutes",
            artworkURL: nil,
            previewURL: URL(filePath: "/previews/1.m4a")
        )
        state.isPlaying = true
        state.duration = 30
        state.position = 12
        return state
    }()

    @Test("Shows the song, its length, the position and a running clock")
    func mapsThePlayingSong() throws {
        let info = try #require(NowPlayingRepositoryImpl.info(for: playing))

        #expect(info[MPMediaItemPropertyTitle] as? String == "Yellow")
        #expect(info[MPMediaItemPropertyArtist] as? String == "Coldplay")
        #expect(info[MPMediaItemPropertyAlbumTitle] as? String == "Parachutes")
        #expect(info[MPMediaItemPropertyPlaybackDuration] as? TimeInterval == 30)
        #expect(info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? TimeInterval == 12)
        #expect(info[MPNowPlayingInfoPropertyPlaybackRate] as? Double == 1)
    }

    @Test("A paused song stops the lock-screen clock, and no song clears the lock screen")
    func mapsPauseAndNoSong() throws {
        var paused = playing
        paused.isPlaying = false

        let info = try #require(NowPlayingRepositoryImpl.info(for: paused))

        #expect(info[MPNowPlayingInfoPropertyPlaybackRate] as? Double == 0)
        #expect(NowPlayingRepositoryImpl.info(for: .idle) == nil)
    }

    @Test("Plain progress leaves the lock screen alone; a seek or a pause updates it")
    func updatesOnlyWhenTheClockCannotTell() {
        var tick = playing
        tick.position += 0.5
        var seek = playing
        seek.position = 25
        var paused = playing
        paused.isPlaying = false

        #expect(!NowPlayingRepositoryImpl.changesTheLockScreen(from: playing, to: tick))
        #expect(NowPlayingRepositoryImpl.changesTheLockScreen(from: playing, to: seek))
        #expect(NowPlayingRepositoryImpl.changesTheLockScreen(from: playing, to: paused))
    }

    @Test("Passes a button on only while a song is shown")
    func forwardsButtonsWithASong() {
        let repository = NowPlayingRepositoryImpl()
        var received: [RemoteCommandType] = []
        repository.onCommand = { received.append($0) }

        #expect(repository.send(.next) == .noActionableNowPlayingItem)
        repository.show(playing)

        #expect(repository.send(.next) == .success)
        #expect(received == [.next])
    }
}

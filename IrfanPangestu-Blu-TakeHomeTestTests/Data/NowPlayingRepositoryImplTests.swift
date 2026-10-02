import Foundation
@testable import IrfanPangestu_Blu_TakeHomeTest
import MediaPlayer
import Testing
import UIKit

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
        let info = try #require(NowPlayingRepositoryImpl.info(for: playing, artwork: nil))

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

        let info = try #require(NowPlayingRepositoryImpl.info(for: paused, artwork: nil))

        #expect(info[MPNowPlayingInfoPropertyPlaybackRate] as? Double == 0)
        #expect(NowPlayingRepositoryImpl.info(for: .idle, artwork: nil) == nil)
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

    @Test("Asks for larger artwork than the list uses")
    func requestsLargerArtwork() throws {
        let listURL = try #require(URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/f5/190295978075.jpg/200x200bb.jpg"))

        let lockScreenURL = NowPlayingRepositoryImpl.lockScreenArtworkURL(from: listURL)

        #expect(lockScreenURL?.absoluteString.hasSuffix("/600x600bb.jpg") == true)
    }

    @Test("Passes a button on only while a song is shown")
    func forwardsButtonsWithASong() {
        let repository = NowPlayingRepositoryImpl(session: .shared)
        var received: [RemoteCommandType] = []
        repository.onCommand = { received.append($0) }

        #expect(repository.send(.next) == .noActionableNowPlayingItem)
        repository.show(playing)

        #expect(repository.send(.next) == .success)
        #expect(received == [.next])
    }

    @Test("A new song goes out without the previous song's artwork")
    func dropsTheOldArtworkWithTheSong() {
        let repository = NowPlayingRepositoryImpl(session: .shared)
        repository.show(playing)
        repository.applyArtwork(Self.image, for: 1)
        #expect(Self.shownInfo?[MPMediaItemPropertyArtwork] != nil)

        repository.show(Self.state(playing: .sample(id: 2, title: "Song 2")))

        #expect(Self.shownInfo?[MPMediaItemPropertyTitle] as? String == "Song 2")
        #expect(Self.shownInfo?[MPMediaItemPropertyArtwork] == nil)
    }

    @Test("Artwork that arrives after the song changed is dropped")
    func dropsLateArtwork() {
        let repository = NowPlayingRepositoryImpl(session: .shared)
        repository.show(playing)
        repository.show(Self.state(playing: .sample(id: 2, title: "Song 2")))

        repository.applyArtwork(Self.image, for: 1)

        #expect(Self.shownInfo?[MPMediaItemPropertyArtwork] == nil)
    }

    private static let image = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { _ in }

    private static var shownInfo: [String: Any]? {
        MPNowPlayingInfoCenter.default().nowPlayingInfo
    }

    private static func state(playing song: SongModel) -> PlaybackStateModel {
        var state = PlaybackStateModel.idle
        state.currentSong = song
        state.isPlaying = true
        state.duration = 30
        return state
    }
}

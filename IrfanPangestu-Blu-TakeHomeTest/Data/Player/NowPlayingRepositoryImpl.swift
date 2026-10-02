import MediaPlayer
import UIKit

/// The lock screen, Control Center and headphone buttons through MediaPlayer. Like AVPlayer it only means something
/// on a device, so the mapping it relies on is unit-tested and the rest is checked there.
@MainActor
final class NowPlayingRepositoryImpl: NowPlayingRepository {
    var onCommand: ((RemoteCommandType) -> Void)?

    private let session: URLSession
    private var shownState = PlaybackStateModel.idle
    private var artworkSongID: Int?
    private var artwork: MPMediaItemArtwork?
    private var artworkTask: Task<Void, Never>?

    /// The app chooses the session for the artwork, as it does for the song search.
    init(session: URLSession) {
        self.session = session
        registerCommands()
    }

    func show(_ state: PlaybackStateModel) {
        guard Self.changesTheLockScreen(from: shownState, to: state) else {
            return
        }
        shownState = state
        // Before publishing, so a new song never goes out with the previous song's artwork.
        if let song = state.currentSong {
            loadArtwork(for: song)
        }
        publish()
    }

    /// The lock screen runs its own clock from the playback rate, so plain progress needs no update; a seek does.
    static func changesTheLockScreen(from old: PlaybackStateModel, to new: PlaybackStateModel) -> Bool {
        var advanced = old
        advanced.position = new.position
        return advanced != new || abs(new.position - old.position) > 1
    }

    /// What the lock screen shows; `nil` clears it.
    static func info(for state: PlaybackStateModel, artwork: MPMediaItemArtwork?) -> [String: Any]? {
        guard let song = state.currentSong else {
            return nil
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artist,
            MPMediaItemPropertyAlbumTitle: song.album,
            MPMediaItemPropertyPlaybackDuration: state.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: state.position,
            MPNowPlayingInfoPropertyPlaybackRate: state.isPlaying ? 1.0 : 0.0
        ]
        info[MPMediaItemPropertyArtwork] = artwork
        return info
    }

    /// The list loads 200 px artwork; the lock screen shows it far larger.
    static func lockScreenArtworkURL(from url: URL) -> URL? {
        URL(string: url.absoluteString.replacingOccurrences(of: "200x200bb", with: "600x600bb"))
    }

    /// Without a song on the lock screen there is nothing for a button to act on.
    func send(_ command: RemoteCommandType) -> MPRemoteCommandHandlerStatus {
        guard shownState.currentSong != nil, let onCommand else {
            return .noActionableNowPlayingItem
        }
        onCommand(command)
        return .success
    }

    private func publish() {
        let commands = MPRemoteCommandCenter.shared()
        commands.nextTrackCommand.isEnabled = shownState.hasNext
        commands.previousTrackCommand.isEnabled = shownState.currentSong != nil
        commands.changePlaybackPositionCommand.isEnabled = shownState.duration > 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = Self.info(for: shownState, artwork: artwork)
    }

    /// MediaPlayer calls these on the main thread, which `assumeIsolated` checks.
    private func registerCommands() {
        let commands = MPRemoteCommandCenter.shared()
        let buttons: [(MPRemoteCommand, RemoteCommandType)] = [
            (commands.playCommand, .play),
            (commands.pauseCommand, .pause),
            (commands.togglePlayPauseCommand, .togglePlayPause),
            (commands.nextTrackCommand, .next),
            (commands.previousTrackCommand, .previous)
        ]
        for (button, command) in buttons {
            button.addTarget { @Sendable [weak self] _ in
                MainActor.assumeIsolated { self?.send(command) ?? .commandFailed }
            }
        }
        commands.changePlaybackPositionCommand.addTarget { @Sendable [weak self] event in
            guard let position = (event as? MPChangePlaybackPositionCommandEvent)?.positionTime else {
                return .commandFailed
            }
            return MainActor.assumeIsolated { self?.send(.seek(position: position)) ?? .commandFailed }
        }
    }

    /// Fetched once per song; the info goes out again when the image arrives.
    private func loadArtwork(for song: SongModel) {
        guard song.id != artworkSongID else {
            return
        }
        artworkSongID = song.id
        artwork = nil
        artworkTask?.cancel()
        guard let url = song.artworkURL.flatMap(Self.lockScreenArtworkURL) else {
            return
        }
        artworkTask = Task { [weak self, session] in
            guard let response = try? await session.data(from: url), let image = UIImage(data: response.0),
                  !Task.isCancelled else {
                return
            }
            self?.applyArtwork(image, for: song.id)
        }
    }

    /// An image that arrives after another song took over is dropped.
    func applyArtwork(_ image: UIImage, for songID: Int) {
        guard songID == artworkSongID else {
            return
        }
        // MediaPlayer asks for the image off the main thread, so the handler must not be main-actor isolated.
        artwork = MPMediaItemArtwork(boundsSize: image.size) { @Sendable _ in image }
        publish()
    }
}

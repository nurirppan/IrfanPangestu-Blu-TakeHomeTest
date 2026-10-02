import MediaPlayer

/// The lock screen, Control Center and headphone buttons through MediaPlayer. Like AVPlayer it only means something
/// on a device, so the mapping it relies on is unit-tested and the rest is checked there.
@MainActor
final class NowPlayingRepositoryImpl: NowPlayingRepository {
    var onCommand: ((RemoteCommandType) -> Void)?

    private var shownState = PlaybackStateModel.idle

    init() {
        registerCommands()
    }

    func show(_ state: PlaybackStateModel) {
        guard Self.changesTheLockScreen(from: shownState, to: state) else {
            return
        }
        shownState = state
        publish()
    }

    /// The lock screen runs its own clock from the playback rate, so plain progress needs no update; a seek does.
    static func changesTheLockScreen(from old: PlaybackStateModel, to new: PlaybackStateModel) -> Bool {
        var advanced = old
        advanced.position = new.position
        return advanced != new || abs(new.position - old.position) > 1
    }

    /// What the lock screen shows; `nil` clears it.
    static func info(for state: PlaybackStateModel) -> [String: Any]? {
        guard let song = state.currentSong else {
            return nil
        }
        return [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artist,
            MPMediaItemPropertyAlbumTitle: song.album,
            MPMediaItemPropertyPlaybackDuration: state.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: state.position,
            MPNowPlayingInfoPropertyPlaybackRate: state.isPlaying ? 1.0 : 0.0
        ]
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
        MPNowPlayingInfoCenter.default().nowPlayingInfo = Self.info(for: shownState)
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
}

import Foundation

/// What the player is doing right now; every screen that shows playback renders from this one value.
struct PlaybackStateModel: Equatable, Sendable {
    static let idle = PlaybackStateModel()

    var currentSong: SongModel?
    var isPlaying = false
    var isBuffering = false
    var position: TimeInterval = 0
    var duration: TimeInterval = 0
    var hasNext = false
    var hasPrevious = false
    var error: AppErrorType?
}

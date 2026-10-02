import Foundation

/// What the player reports back; the use case turns these into `PlaybackStateModel`.
enum PlayerEventType: Equatable, Sendable {
    case progress(position: TimeInterval, duration: TimeInterval)
    case status(isPlaying: Bool, isBuffering: Bool)
    case finished
    case failed(AppErrorType)
}

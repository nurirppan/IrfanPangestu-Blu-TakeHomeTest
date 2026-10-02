import Foundation

/// A button pressed on the lock screen, in Control Center or on headphones.
enum RemoteCommandType: Equatable, Sendable {
    case play
    case pause
    case togglePlayPause
    case next
    case previous
    case seek(position: TimeInterval)
}

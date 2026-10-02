import Foundation

/// Plays one URL at a time and reports what happens. The data layer implements it with AVPlayer.
@MainActor
protocol PlayerRepository: AnyObject {
    var onEvent: ((PlayerEventType) -> Void)? { get set }

    func play(url: URL)
    func pause()
    func resume()
    func seek(to position: TimeInterval)
}

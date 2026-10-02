import AVFoundation
import Foundation

/// Thin AVPlayer wrapper. Its behaviour only means something on a device, so it is checked there, not in unit tests.
@MainActor
final class PlayerRepositoryImpl: PlayerRepository {
    var onEvent: ((PlayerEventType) -> Void)?

    private let player = AVPlayer()

    func play(url: URL) {
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        player.play()
    }

    func pause() {
        player.pause()
    }

    func resume() {
        player.play()
    }

    func seek(to position: TimeInterval) {
        player.seek(to: CMTime(seconds: position, preferredTimescale: 600))
    }
}

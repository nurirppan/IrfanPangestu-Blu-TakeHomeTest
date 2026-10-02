import Foundation
@testable import IrfanPangestu_Blu_TakeHomeTest

/// Records every command and lets a test send player events by hand.
@MainActor
final class FakePlayerRepository: PlayerRepository {
    var onEvent: ((PlayerEventType) -> Void)?

    private(set) var playedURLs: [URL] = []
    private(set) var pauseCount = 0
    private(set) var resumeCount = 0
    private(set) var seekPositions: [TimeInterval] = []

    func play(url: URL) {
        playedURLs.append(url)
    }

    func pause() {
        pauseCount += 1
    }

    func resume() {
        resumeCount += 1
    }

    func seek(to position: TimeInterval) {
        seekPositions.append(position)
    }

    func send(_ event: PlayerEventType) {
        onEvent?(event)
    }
}

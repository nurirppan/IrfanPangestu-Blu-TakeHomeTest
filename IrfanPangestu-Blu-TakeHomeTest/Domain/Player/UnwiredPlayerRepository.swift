import Foundation

/// Reports a failure instead of playing silently, so a missing registration shows on screen.
@MainActor
final class UnwiredPlayerRepository: PlayerRepository {
    var onEvent: ((PlayerEventType) -> Void)?

    init() {}

    func play(url: URL) {
        onEvent?(.failed(.localError(message: "PlayerRepository is not wired. Register PlayerRepositoryImpl in autoRegister().")))
    }

    func pause() {}

    func resume() {}

    func seek(to position: TimeInterval) {}
}

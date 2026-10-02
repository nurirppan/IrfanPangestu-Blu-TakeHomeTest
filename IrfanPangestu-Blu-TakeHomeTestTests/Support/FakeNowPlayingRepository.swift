@testable import IrfanPangestu_Blu_TakeHomeTest

/// Records what the lock screen was asked to show and lets a test press its buttons.
@MainActor
final class FakeNowPlayingRepository: NowPlayingRepository {
    var onCommand: ((RemoteCommandType) -> Void)?

    private(set) var shownStates: [PlaybackStateModel] = []

    func show(_ state: PlaybackStateModel) {
        shownStates.append(state)
    }

    func press(_ command: RemoteCommandType) {
        onCommand?(command)
    }
}

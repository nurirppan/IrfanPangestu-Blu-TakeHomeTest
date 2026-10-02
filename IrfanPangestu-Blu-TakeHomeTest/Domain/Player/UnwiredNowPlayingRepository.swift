import os

/// Has no screen of its own to fail on, so a missing registration is reported as a fault in the log at once.
@MainActor
final class UnwiredNowPlayingRepository: NowPlayingRepository {
    var onCommand: ((RemoteCommandType) -> Void)?

    /// `report` writes to the system log; a test passes its own to read the message.
    init(report: (String) -> Void = { UnwiredNowPlayingRepository.log.fault("\($0, privacy: .public)") }) {
        report("NowPlayingRepository is not wired. Register NowPlayingRepositoryImpl in autoRegister().")
    }

    func show(_ state: PlaybackStateModel) {}

    private static let log = Logger(subsystem: "com.irfanpangestu.takehometest", category: "DI")
}

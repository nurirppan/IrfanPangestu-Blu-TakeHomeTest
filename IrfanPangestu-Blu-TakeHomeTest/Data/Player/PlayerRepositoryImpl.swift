import AVFoundation
import Combine
import Foundation

/// Thin AVPlayer wrapper. Its behaviour only means something on a device, so it is checked there, not in unit tests.
@MainActor
final class PlayerRepositoryImpl: PlayerRepository {
    var onEvent: ((PlayerEventType) -> Void)?

    private let player = AVPlayer()
    private var timeObserver: Any?
    private var playerCancellables = Set<AnyCancellable>()
    private var itemCancellables = Set<AnyCancellable>()

    init() {
        observePlayer()
        observeAudioSession()
    }

    func play(url: URL) {
        activateAudioSession()
        let item = AVPlayerItem(url: url)
        observe(item)
        player.replaceCurrentItem(with: item)
        player.play()
    }

    func pause() {
        player.pause()
    }

    func resume() {
        activateAudioSession()
        player.play()
    }

    func seek(to position: TimeInterval) {
        player.seek(to: CMTime(seconds: position, preferredTimescale: 600))
    }

    private func observePlayer() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            let seconds = time.seconds
            MainActor.assumeIsolated {
                self?.reportProgress(at: seconds)
            }
        }
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.report(status)
            }
            .store(in: &playerCancellables)
    }

    /// Item observers are replaced with the item, so a finished or failed old song can't report into the new one.
    private func observe(_ item: AVPlayerItem) {
        itemCancellables.removeAll()
        item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .filter { $0 == .failed }
            .sink { [weak self] _ in
                self?.onEvent?(.failed(.playbackFailed))
            }
            .store(in: &itemCancellables)
        NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.onEvent?(.finished)
            }
            .store(in: &itemCancellables)
        NotificationCenter.default.publisher(for: AVPlayerItem.failedToPlayToEndTimeNotification, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.onEvent?(.failed(.playbackFailed))
            }
            .store(in: &itemCancellables)
    }

    /// The duration is NaN until the item is ready; report 0 so the slider stays disabled until then.
    private func reportProgress(at seconds: Double) {
        guard let item = player.currentItem else {
            return
        }
        let duration = item.duration.seconds
        onEvent?(.progress(position: max(seconds, 0), duration: duration.isFinite ? duration : 0))
    }

    /// `.playback` keeps the sound on when the silent switch is on.
    private func activateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
    }

    private func observeAudioSession() {
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleInterruption(notification)
            }
            .store(in: &playerCancellables)
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleRouteChange(notification)
            }
            .store(in: &playerCancellables)
    }

    /// A phone call took the audio; stay paused afterwards instead of resuming by surprise.
    private func handleInterruption(_ notification: Notification) {
        guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: rawType) == .began else {
            return
        }
        player.pause()
    }

    /// Unplugged headphones would otherwise move the sound to the speaker.
    private func handleRouteChange(_ notification: Notification) {
        guard let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              AVAudioSession.RouteChangeReason(rawValue: rawReason) == .oldDeviceUnavailable else {
            return
        }
        player.pause()
    }

    private func report(_ status: AVPlayer.TimeControlStatus) {
        switch status {
        case .playing:
            onEvent?(.status(isPlaying: true, isBuffering: false))
        case .waitingToPlayAtSpecifiedRate:
            onEvent?(.status(isPlaying: true, isBuffering: true))
        case .paused:
            onEvent?(.status(isPlaying: false, isBuffering: false))
        @unknown default:
            break
        }
    }
}

import Combine
import FactoryKit
import Foundation

/// Turns the shared player state into what the controls bar shows.
@MainActor
final class PlayerControlsVM: ObservableObject {
    @Published private(set) var state = PlaybackStateModel.idle
    @Published var sliderPosition: TimeInterval = 0

    private let playerUseCase: any MusicPlayerUseCase
    private var isScrubbing = false
    private var cancellables = Set<AnyCancellable>()

    init(playerUseCase: any MusicPlayerUseCase = Container.shared.musicPlayerUseCase()) {
        self.playerUseCase = playerUseCase
        playerUseCase.statePublisher
            .sink { [weak self] state in
                self?.apply(state)
            }
            .store(in: &cancellables)
    }

    var isVisible: Bool {
        state.currentSong != nil
    }

    var title: String {
        state.currentSong?.title ?? ""
    }

    var artist: String {
        state.currentSong?.artist ?? ""
    }

    /// While the preview buffers, the play button shows a spinner instead of an icon.
    var isBuffering: Bool {
        state.isBuffering
    }

    var playButtonSymbol: String {
        state.isPlaying ? "pause.fill" : "play.fill"
    }

    var playButtonLabel: String {
        if state.isBuffering {
            return String(localized: "Loading")
        }
        return state.isPlaying ? String(localized: "Pause") : String(localized: "Play")
    }

    var positionDescription: String {
        String(localized: "\(elapsedText) of \(durationText)")
    }

    var isNextEnabled: Bool {
        state.hasNext
    }

    /// Previous works as soon as a song is chosen: on the first song it restarts it.
    var isPreviousEnabled: Bool {
        state.currentSong != nil
    }

    /// The duration is unknown until the preview is ready, so the slider waits for it.
    var isSliderEnabled: Bool {
        state.duration > 0
    }

    var sliderRange: ClosedRange<TimeInterval> {
        0...max(state.duration, 1)
    }

    var elapsedText: String {
        TimeFormatterType.string(from: sliderPosition)
    }

    var durationText: String {
        TimeFormatterType.string(from: state.duration)
    }

    var errorMessage: String? {
        state.error.map { AppErrorPresentationModel(error: $0).message }
    }

    func togglePlayPause() {
        playerUseCase.togglePlayPause()
    }

    func next() {
        playerUseCase.next()
    }

    func previous() {
        playerUseCase.previous()
    }

    /// `true` when a drag starts, `false` when it ends. Seeking only on release keeps the audio from stuttering.
    func scrubbingChanged(_ isEditing: Bool) {
        isScrubbing = isEditing
        if !isEditing {
            playerUseCase.seek(to: sliderPosition)
        }
    }

    /// A move without a drag, such as a VoiceOver swipe, has no release to wait for, so it seeks at once.
    func seek(to position: TimeInterval) {
        sliderPosition = position
        playerUseCase.seek(to: position)
    }

    private func apply(_ newState: PlaybackStateModel) {
        state = newState
        if !isScrubbing {
            sliderPosition = newState.position
        }
    }
}

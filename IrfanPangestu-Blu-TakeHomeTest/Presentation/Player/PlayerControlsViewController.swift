import Combine
import UIKit

/// Previous, play/pause, next and a slider for the song that's playing; hides itself until a song is chosen.
/// The layout lives in PlayerControlsViewController.xib, where the labels and slider resist compression at 1000:
/// on iOS 26 an active search pulls the list above down at 999 and would squeeze them to nothing.
final class PlayerControlsViewController: UIViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var artistLabel: UILabel!
    @IBOutlet private weak var slider: UISlider!
    @IBOutlet private weak var elapsedLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var previousButton: UIButton!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var bufferingIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var errorLabel: UILabel!

    private let viewModel: PlayerControlsVM
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: PlayerControlsVM = PlayerControlsVM()) {
        self.viewModel = viewModel
        super.init(nibName: "PlayerControlsViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(viewModel:)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        configureControls()
        viewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.render()
            }
            .store(in: &cancellables)
        render()
    }

    private func configureControls() {
        let symbolSize = UIImage.SymbolConfiguration(textStyle: .title2)
        previousButton.setImage(UIImage(systemName: "backward.fill", withConfiguration: symbolSize), for: .normal)
        nextButton.setImage(UIImage(systemName: "forward.fill", withConfiguration: symbolSize), for: .normal)
        previousButton.accessibilityLabel = String(localized: "Previous song")
        nextButton.accessibilityLabel = String(localized: "Next song")
        slider.accessibilityLabel = String(localized: "Position")
        // Only a font scaled through UIFontMetrics keeps following the text size after launch; 12 pt is caption1's default.
        let timeFont = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .monospacedDigitSystemFont(ofSize: 12, weight: .regular))
        elapsedLabel.font = timeFont
        durationLabel.font = timeFont
        elapsedLabel.textColor = .secondaryLabel
        durationLabel.textColor = .secondaryLabel
        artistLabel.textColor = .secondaryLabel
        errorLabel.textColor = .systemRed
    }

    private func render() {
        view.isHidden = !viewModel.isVisible
        titleLabel.text = viewModel.title
        artistLabel.text = viewModel.artist
        slider.isEnabled = viewModel.isSliderEnabled
        slider.maximumValue = Float(viewModel.sliderRange.upperBound)
        if !slider.isTracking {
            slider.value = Float(viewModel.sliderPosition)
        }
        slider.accessibilityValue = viewModel.positionDescription
        elapsedLabel.text = viewModel.elapsedText
        durationLabel.text = viewModel.durationText
        previousButton.isEnabled = viewModel.isPreviousEnabled
        nextButton.isEnabled = viewModel.isNextEnabled
        errorLabel.text = viewModel.errorMessage
        errorLabel.isHidden = viewModel.errorMessage == nil
        renderPlayButton()
    }

    /// While the preview buffers a spinner takes the play button's place; `alpha` keeps the buttons from shifting.
    private func renderPlayButton() {
        let symbolSize = UIImage.SymbolConfiguration(textStyle: .largeTitle)
        playPauseButton.setImage(UIImage(systemName: viewModel.playButtonSymbol, withConfiguration: symbolSize), for: .normal)
        playPauseButton.accessibilityLabel = viewModel.playButtonLabel
        playPauseButton.alpha = viewModel.isBuffering ? 0 : 1
        if viewModel.isBuffering {
            bufferingIndicator.startAnimating()
        } else {
            bufferingIndicator.stopAnimating()
        }
    }

    @IBAction private func previousTapped() {
        viewModel.previous()
    }

    @IBAction private func playPauseTapped() {
        viewModel.togglePlayPause()
    }

    @IBAction private func nextTapped() {
        viewModel.next()
    }

    @IBAction private func sliderTouchDown(_ sender: UISlider) {
        viewModel.scrubbingChanged(true)
    }

    /// VoiceOver moves the slider without touching it, and then no release event follows.
    @IBAction private func sliderValueChanged(_ sender: UISlider) {
        if sender.isTracking {
            viewModel.sliderPosition = TimeInterval(sender.value)
        } else {
            viewModel.seek(to: TimeInterval(sender.value))
        }
    }

    /// Seeking once, on release, keeps the preview from stuttering while the thumb moves.
    @IBAction private func sliderReleased(_ sender: UISlider) {
        viewModel.scrubbingChanged(false)
    }
}

import UIKit

/// One row of the song list: artwork, title, artist, album, and a wave icon on the current song. The layout lives
/// in SongTableViewCell.xib.
final class SongTableViewCell: UITableViewCell {
    static let reuseIdentifier = "SongTableViewCell"
    static let nib = UINib(nibName: "SongTableViewCell", bundle: nil)

    @IBOutlet private weak var artworkImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var artistLabel: UILabel!
    @IBOutlet private weak var albumLabel: UILabel!
    @IBOutlet private weak var playingImageView: UIImageView!

    private var artworkTask: Task<Void, Never>?

    /// The icon never changes, so it is set once.
    override func awakeFromNib() {
        super.awakeFromNib()
        // NSObject declares this nonisolated, but nibs load on the main thread, which `assumeIsolated` checks.
        MainActor.assumeIsolated {
            playingImageView.image = UIImage(systemName: "waveform")
        }
    }

    /// A reused cell must not show the previous song's artwork while the new one downloads.
    override func prepareForReuse() {
        super.prepareForReuse()
        artworkTask?.cancel()
        artworkImageView.image = nil
    }

    func configure(with song: SongModel, isCurrent: Bool, isPlaying: Bool) {
        titleLabel.text = song.title
        artistLabel.text = song.artist
        artistLabel.textColor = .secondaryLabel
        albumLabel.text = song.album
        albumLabel.textColor = .secondaryLabel
        artworkImageView.backgroundColor = .quaternarySystemFill
        playingImageView.isHidden = !isCurrent
        backgroundColor = isCurrent ? tintColor.withAlphaComponent(0.12) : nil
        let playback = isPlaying ? String(localized: "Now playing") : String(localized: "Paused")
        accessibilityValue = isCurrent ? playback : nil
        loadArtwork(from: song.artworkURL)
    }

    private func loadArtwork(from url: URL?) {
        artworkTask?.cancel()
        guard let url else {
            artworkImageView.image = nil
            return
        }
        if let cached = ImageLoader.shared.cachedImage(for: url) {
            artworkImageView.image = cached
            return
        }
        artworkImageView.image = nil
        artworkTask = Task { [weak self] in
            let image = await ImageLoader.shared.image(for: url)
            guard !Task.isCancelled else {
                return
            }
            self?.artworkImageView.image = image
        }
    }
}

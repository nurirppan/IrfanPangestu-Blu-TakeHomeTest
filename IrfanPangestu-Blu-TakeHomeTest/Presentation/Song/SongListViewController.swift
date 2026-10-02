import Combine
import UIKit

/// Searches iTunes and lists the songs, with loading, empty and error states. The layout lives in
/// SongListViewController.xib; searching starts from the keyboard's Search button, not on every keystroke.
final class SongListViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var statusStackView: UIStackView!
    @IBOutlet private weak var statusImageView: UIImageView!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var retryButton: UIButton!
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!

    private let viewModel: SongListVM
    private let searchController = UISearchController(searchResultsController: nil)
    private var dataSource: UITableViewDiffableDataSource<Int, SongModel>?
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: SongListVM = SongListVM()) {
        self.viewModel = viewModel
        super.init(nibName: "SongListViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(viewModel:)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = String(localized: "Music")
        configureSearch()
        configureTable()
        retryButton.configuration?.title = String(localized: "Retry")
        // `objectWillChange` fires before the change lands, so render on the next main-queue turn.
        viewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.render()
            }
            .store(in: &cancellables)
        render()
    }

    private func configureSearch() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = String(localized: "Search artist")
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        // iOS 26 would move the search bar into a bottom toolbar; the layout keeps it above the list.
        navigationItem.preferredSearchBarPlacement = .stacked
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func configureTable() {
        tableView.register(SongTableViewCell.nib, forCellReuseIdentifier: SongTableViewCell.reuseIdentifier)
        tableView.delegate = self
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, song in
            let cell = tableView.dequeueReusableCell(withIdentifier: SongTableViewCell.reuseIdentifier, for: indexPath)
            let isCurrent = song.id == self?.viewModel.playingSongID
            (cell as? SongTableViewCell)?.configure(with: song, isCurrent: isCurrent, isPlaying: self?.viewModel.isPlaying == true)
            return cell
        }
    }

    private func render() {
        switch viewModel.state {
        case .idle:
            let message = String(localized: "Search an artist to start")
            showStatus(systemImage: "magnifyingglass", message: message, canRetry: false)
        case .loading:
            showLoading()
        case .loaded(let songs):
            showSongs(songs)
        case .empty(let term):
            let message = String(localized: "No songs found for “\(term)”")
            showStatus(systemImage: "music.note.list", message: message, canRetry: false)
        case .failed(let error):
            let presentation = AppErrorPresentationModel(error: error)
            showStatus(systemImage: "exclamationmark.triangle", message: presentation.message, canRetry: presentation.canRetry)
        }
    }

    /// Reconfiguring every row keeps the playing mark right after the song changes, pauses or resumes.
    private func showSongs(_ songs: [SongModel]) {
        loadingIndicator.stopAnimating()
        statusStackView.isHidden = true
        tableView.isHidden = false
        var snapshot = NSDiffableDataSourceSnapshot<Int, SongModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(songs)
        snapshot.reconfigureItems(songs)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    private func showLoading() {
        tableView.isHidden = true
        statusStackView.isHidden = true
        loadingIndicator.startAnimating()
    }

    private func showStatus(systemImage: String, message: String, canRetry: Bool) {
        loadingIndicator.stopAnimating()
        tableView.isHidden = true
        statusStackView.isHidden = false
        statusImageView.image = UIImage(systemName: systemImage)
        statusImageView.tintColor = .secondaryLabel
        statusLabel.text = message
        statusLabel.textColor = .secondaryLabel
        retryButton.isHidden = !canRetry
    }

    @IBAction private func retryTapped() {
        viewModel.submitRetry()
    }
}

extension SongListViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        viewModel.query = searchBar.text ?? ""
        viewModel.submitSearch()
        searchBar.resignFirstResponder()
    }
}

extension SongListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let song = dataSource?.itemIdentifier(for: indexPath) else {
            return
        }
        viewModel.didSelect(song)
    }
}

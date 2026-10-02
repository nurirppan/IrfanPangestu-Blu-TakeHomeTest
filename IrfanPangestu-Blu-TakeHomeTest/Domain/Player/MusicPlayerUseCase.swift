import Combine
import Foundation

/// The player's business rules: the queue, autoplay, and what a tap on a song means.
@MainActor
protocol MusicPlayerUseCase: AnyObject {
    var state: PlaybackStateModel { get }
    /// Sends the current state on subscription, then every change. Several view models subscribe at once.
    var statePublisher: AnyPublisher<PlaybackStateModel, Never> { get }

    func play(songs: [SongModel], startAt index: Int)
    func togglePlayPause()
    func next()
    func previous()
    func seek(to position: TimeInterval)
}

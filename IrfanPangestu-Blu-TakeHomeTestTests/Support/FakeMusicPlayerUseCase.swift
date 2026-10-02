import Combine
import Foundation
@testable import IrfanPangestu_Blu_TakeHomeTest

/// Publishes whatever state a test sets and records the commands it receives.
@MainActor
final class FakeMusicPlayerUseCase: MusicPlayerUseCase {
    var state = PlaybackStateModel.idle {
        didSet {
            subject.send(state)
        }
    }

    var statePublisher: AnyPublisher<PlaybackStateModel, Never> {
        subject.eraseToAnyPublisher()
    }

    private(set) var commands: [String] = []
    private(set) var playedSongs: [SongModel] = []
    private(set) var playedIndex: Int?
    private let subject = CurrentValueSubject<PlaybackStateModel, Never>(.idle)

    func play(songs: [SongModel], startAt index: Int) {
        playedSongs = songs
        playedIndex = index
    }

    func togglePlayPause() {
        commands.append("toggle")
    }

    func next() {
        commands.append("next")
    }

    func previous() {
        commands.append("previous")
    }

    func seek(to position: TimeInterval) {
        commands.append("seek \(Int(position))")
    }
}

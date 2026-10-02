/// The list being played and the position in it. Next stops at the last song; the caller decides what previous
/// means on the first one.
struct PlaybackQueue: Equatable, Sendable {
    private var songs: [SongModel] = []
    private var currentIndex: Int?

    init() {}

    var current: SongModel? {
        currentIndex.map { songs[$0] }
    }

    var hasNext: Bool {
        guard let currentIndex else {
            return false
        }
        return currentIndex + 1 < songs.count
    }

    var hasPrevious: Bool {
        guard let currentIndex else {
            return false
        }
        return currentIndex > 0
    }

    /// Replaces the queue with `songs` and moves to `index`; an index outside the list leaves the queue unchanged.
    @discardableResult
    mutating func select(songs: [SongModel], at index: Int) -> SongModel? {
        guard songs.indices.contains(index) else {
            return nil
        }
        self.songs = songs
        currentIndex = index
        return songs[index]
    }

    @discardableResult
    mutating func next() -> SongModel? {
        guard hasNext, let currentIndex else {
            return nil
        }
        self.currentIndex = currentIndex + 1
        return current
    }

    @discardableResult
    mutating func previous() -> SongModel? {
        guard hasPrevious, let currentIndex else {
            return nil
        }
        self.currentIndex = currentIndex - 1
        return current
    }
}

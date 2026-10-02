@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

struct PlaybackQueueTests {
    private let songs = [SongModel.sample(id: 1), .sample(id: 2), .sample(id: 3)]

    @Test("An empty queue has no current song and nowhere to go")
    func emptyQueue() {
        var queue = PlaybackQueue()

        #expect(queue.current == nil)
        #expect(!queue.hasNext)
        #expect(!queue.hasPrevious)
        #expect(queue.next() == nil)
        #expect(queue.previous() == nil)
    }

    @Test("Selecting a song makes it current")
    func selectsSong() {
        var queue = PlaybackQueue()

        #expect(queue.select(songs: songs, at: 1) == songs[1])
        #expect(queue.current == songs[1])
        #expect(queue.hasNext)
        #expect(queue.hasPrevious)
    }

    @Test("An index outside the list changes nothing")
    func ignoresInvalidIndex() {
        var queue = PlaybackQueue()
        queue.select(songs: songs, at: 0)

        #expect(queue.select(songs: songs, at: 5) == nil)
        #expect(queue.current == songs[0])
    }

    @Test("Next and previous walk the list")
    func walksTheList() {
        var queue = PlaybackQueue()
        queue.select(songs: songs, at: 0)

        #expect(queue.next() == songs[1])
        #expect(queue.next() == songs[2])
        #expect(queue.previous() == songs[1])
    }

    @Test("Next stops at the last song")
    func stopsAtTheEnd() {
        var queue = PlaybackQueue()
        queue.select(songs: songs, at: 2)

        #expect(!queue.hasNext)
        #expect(queue.next() == nil)
        #expect(queue.current == songs[2])
    }

    @Test("Previous has nowhere to go from the first song")
    func stopsAtTheStart() {
        var queue = PlaybackQueue()
        queue.select(songs: songs, at: 0)

        #expect(!queue.hasPrevious)
        #expect(queue.previous() == nil)
        #expect(queue.current == songs[0])
    }
}

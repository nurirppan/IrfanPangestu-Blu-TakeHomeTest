@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing
import UIKit

/// A XIB is checked by Interface Builder only, so a broken outlet or module would first show up as a crash on a
/// device. Loading every XIB here makes CI catch it instead.
@MainActor
struct NibLoadingTests {
    @Test("The song cell loads as SongTableViewCell with its outlets connected")
    func songCellLoads() throws {
        let cell = try #require(SongTableViewCell.nib.instantiate(withOwner: nil).first as? SongTableViewCell)

        cell.configure(with: .sample(id: 1, title: "Yellow"), isCurrent: true, isPlaying: true)

        #expect(cell.reuseIdentifier == SongTableViewCell.reuseIdentifier)
        #expect(cell.accessibilityValue == "Now playing")
    }

    @Test("VoiceOver hears whether the marked song plays or is paused")
    func songCellDescribesPlayback() throws {
        let cell = try #require(SongTableViewCell.nib.instantiate(withOwner: nil).first as? SongTableViewCell)

        cell.configure(with: .sample(id: 1), isCurrent: true, isPlaying: false)
        #expect(cell.accessibilityValue == "Paused")

        cell.configure(with: .sample(id: 2), isCurrent: false, isPlaying: true)
        #expect(cell.accessibilityValue == nil)
    }
}

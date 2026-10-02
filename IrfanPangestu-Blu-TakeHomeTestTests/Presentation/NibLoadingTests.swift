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

    @Test("The song list loads its XIB and starts on the idle message")
    func songListLoads() {
        let viewModel = SongListVM(
            searchUseCase: StubSearchSongsUseCase(results: [.success([])]),
            playerUseCase: FakeMusicPlayerUseCase()
        )
        let controller = SongListViewController(viewModel: viewModel)

        controller.loadViewIfNeeded()

        let texts = controller.view.descendants(of: UILabel.self).compactMap(\.text)
        #expect(texts.contains("Search an artist to start"))
        #expect(controller.navigationItem.searchController != nil)
        #expect(controller.navigationItem.preferredSearchBarPlacement == .stacked)
        #expect(!controller.view.descendants(of: UITableView.self).isEmpty)
    }

    @Test("The player controls stay hidden until a song is chosen")
    func playerControlsHideWithoutSong() {
        let controller = PlayerControlsViewController(viewModel: PlayerControlsVM(playerUseCase: FakeMusicPlayerUseCase()))

        controller.loadViewIfNeeded()

        #expect(controller.view.isHidden)
    }

    @Test("The player controls load their XIB and show the playing song")
    func playerControlsShowSong() {
        let useCase = FakeMusicPlayerUseCase()
        var state = PlaybackStateModel.idle
        state.currentSong = .sample(id: 1, title: "Yellow")
        state.isPlaying = true
        state.duration = 30
        state.position = 12
        useCase.state = state
        let controller = PlayerControlsViewController(viewModel: PlayerControlsVM(playerUseCase: useCase))

        controller.loadViewIfNeeded()

        let texts = controller.view.descendants(of: UILabel.self).compactMap(\.text)
        #expect(!controller.view.isHidden)
        #expect(texts.contains("Yellow"))
        #expect(texts.contains("0:12"))
        #expect(texts.contains("0:30"))
    }

    /// On iOS 26 an active search ties the list's bottom to the keyboard guide at priority 999, which squeezed
    /// the title, time and slider to zero height.
    @Test("The player controls keep their height when the list above pulls at priority 999")
    func playerControlsResistSqueezing() {
        let useCase = FakeMusicPlayerUseCase()
        var state = PlaybackStateModel.idle
        state.currentSong = .sample(id: 1, title: "Yellow")
        state.duration = 30
        useCase.state = state
        let controller = PlayerControlsViewController(viewModel: PlayerControlsVM(playerUseCase: useCase))
        let list = UIView()
        let stackView = UIStackView(arrangedSubviews: [list, controller.view])
        stackView.axis = .vertical
        stackView.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        let pull = list.bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        pull.priority = UILayoutPriority(999)
        pull.isActive = true

        stackView.layoutIfNeeded()

        let squeezed = controller.view.descendants(of: UIView.self)
            .filter { ($0 is UILabel || $0 is UISlider) && !$0.isHidden && $0.frame.height == 0 }
        #expect(squeezed.isEmpty, "squeezed: \(squeezed.map { type(of: $0) })")
    }

    @Test("The slider seeks when its value changes without a touch, as VoiceOver changes it")
    func sliderSeeksWithoutTouch() throws {
        let useCase = FakeMusicPlayerUseCase()
        var state = PlaybackStateModel.idle
        state.currentSong = .sample(id: 1)
        state.duration = 30
        useCase.state = state
        let controller = PlayerControlsViewController(viewModel: PlayerControlsVM(playerUseCase: useCase))
        controller.loadViewIfNeeded()
        let slider = try #require(controller.view.descendants(of: UISlider.self).first)

        slider.value = 9
        slider.sendActions(for: .valueChanged)

        #expect(useCase.commands == ["seek 9"])
    }

    @Test("The times grow when the text size changes while the app runs")
    @available(iOS 17.0, *)
    func timesFollowDynamicType() {
        let useCase = FakeMusicPlayerUseCase()
        var state = PlaybackStateModel.idle
        state.currentSong = .sample(id: 1)
        state.duration = 30
        useCase.state = state
        let controller = PlayerControlsViewController(viewModel: PlayerControlsVM(playerUseCase: useCase))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = controller
        window.isHidden = false
        window.layoutIfNeeded()

        window.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        window.layoutIfNeeded()

        let times = controller.view.descendants(of: UILabel.self).filter { $0.text == "0:00" || $0.text == "0:30" }
        #expect(times.count == 2)
        #expect(times.allSatisfy { $0.font.pointSize > 20 }, "sizes: \(times.map(\.font.pointSize))")
    }
}

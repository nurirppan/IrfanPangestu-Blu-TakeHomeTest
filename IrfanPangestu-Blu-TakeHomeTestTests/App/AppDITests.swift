import FactoryKit
@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

/// The tests run inside the app, where autoRegister() has already swapped the unwired defaults for the real ones.
@MainActor
struct AppDITests {
    @Test("AppDI wires the real repositories in place of the unwired defaults")
    func wiresTheRealRepositories() {
        #expect(Container.shared.songRepository() is SongRepositoryImpl)
        #expect(Container.shared.playerRepository() is PlayerRepositoryImpl)
        #expect(Container.shared.nowPlayingRepository() is NowPlayingRepositoryImpl)
    }

    @Test("Every screen gets the same player and the same lock screen")
    func sharesOnePlayer() {
        #expect(Container.shared.musicPlayerUseCase() === Container.shared.musicPlayerUseCase())
        #expect(Container.shared.nowPlayingRepository() === Container.shared.nowPlayingRepository())
    }
}

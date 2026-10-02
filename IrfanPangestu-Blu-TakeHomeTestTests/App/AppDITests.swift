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
    }

    @Test("Every screen gets the same player")
    func sharesOnePlayer() {
        #expect(Container.shared.musicPlayerUseCase() === Container.shared.musicPlayerUseCase())
    }
}

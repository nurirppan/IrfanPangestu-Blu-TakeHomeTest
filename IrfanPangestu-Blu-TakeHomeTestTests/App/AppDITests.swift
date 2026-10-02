import FactoryKit
@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

/// The tests run inside the app, where autoRegister() has already swapped the unwired defaults for the real ones.
struct AppDITests {
    @Test("AppDI wires the real repositories in place of the unwired defaults")
    func wiresTheRealRepositories() {
        #expect(Container.shared.songRepository() is SongRepositoryImpl)
    }
}

import FactoryKit

extension Container {
    /// Throws until the app's `autoRegister()` swaps in the real repository.
    var songRepository: Factory<any SongRepository> {
        self { UnwiredSongRepository() }
    }
}

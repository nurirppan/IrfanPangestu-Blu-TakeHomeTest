import FactoryKit

extension Container {
    /// Throws until the app's `autoRegister()` swaps in the real repository.
    var songRepository: Factory<any SongRepository> {
        self { UnwiredSongRepository() }
    }

    var searchSongsUseCase: Factory<any SearchSongsUseCase> {
        self { SearchSongsUseCaseImpl(repository: self.songRepository()) }
    }
}

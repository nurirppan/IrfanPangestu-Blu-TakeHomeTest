import FactoryKit

extension Container {
    /// Throws until the app's `autoRegister()` swaps in the real repository.
    var songRepository: Factory<any SongRepository> {
        self { UnwiredSongRepository() }
    }

    var searchSongsUseCase: Factory<any SearchSongsUseCase> {
        self { SearchSongsUseCaseImpl(repository: self.songRepository()) }
    }

    /// `.singleton`: every screen must drive the same player. Player types live on the main actor and only
    /// main-actor view models resolve them, so the factory builds them there.
    var playerRepository: Factory<any PlayerRepository> {
        self { MainActor.assumeIsolated { UnwiredPlayerRepository() } }.singleton
    }

    /// `.singleton` for the same reason: one queue and one player, shared by every screen.
    var musicPlayerUseCase: Factory<any MusicPlayerUseCase> {
        self { MainActor.assumeIsolated { MusicPlayerUseCaseImpl(repository: self.playerRepository()) } }.singleton
    }
}

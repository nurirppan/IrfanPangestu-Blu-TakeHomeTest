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

    /// Logs a fault until the app's `autoRegister()` swaps in the real one. `.singleton`: the system has one
    /// lock screen, and a second instance would answer its buttons twice.
    var nowPlayingRepository: Factory<any NowPlayingRepository> {
        self { MainActor.assumeIsolated { UnwiredNowPlayingRepository() } }.singleton
    }

    /// `.singleton`: one lock screen following the one shared player.
    var nowPlayingUseCase: Factory<any NowPlayingUseCase> {
        self {
            MainActor.assumeIsolated {
                NowPlayingUseCaseImpl(playerUseCase: self.musicPlayerUseCase(), repository: self.nowPlayingRepository())
            }
        }.singleton
    }
}

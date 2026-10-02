/// FactoryKit needs a default. Throwing makes a missing registration obvious instead of showing fake data.
struct UnwiredSongRepository: SongRepository {
    func searchSongs(term: String) async throws -> [SongModel] {
        throw AppErrorType.localError(message: "SongRepository is not wired. Register SongRepositoryImpl in autoRegister().")
    }
}

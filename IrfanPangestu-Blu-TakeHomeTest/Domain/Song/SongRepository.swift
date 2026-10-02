/// Remote song catalog. The data layer implements it; the app wires it in `autoRegister()`.
protocol SongRepository: Sendable {
    func searchSongs(term: String) async throws -> [SongModel]
}

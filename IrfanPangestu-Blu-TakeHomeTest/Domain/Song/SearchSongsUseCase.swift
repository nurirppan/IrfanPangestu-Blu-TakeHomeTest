protocol SearchSongsUseCase: Sendable {
    /// Blank input returns an empty list without touching the repository.
    func search(term: String) async throws -> [SongModel]
}

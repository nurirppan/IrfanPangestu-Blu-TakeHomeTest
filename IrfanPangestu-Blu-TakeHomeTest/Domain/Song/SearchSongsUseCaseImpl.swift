import Foundation

/// Normalizes the term before asking the repository, so blank input never reaches the network.
final class SearchSongsUseCaseImpl: SearchSongsUseCase {
    private let repository: any SongRepository

    init(repository: any SongRepository) {
        self.repository = repository
    }

    func search(term: String) async throws -> [SongModel] {
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTerm.isEmpty else {
            return []
        }
        return try await repository.searchSongs(term: trimmedTerm)
    }
}

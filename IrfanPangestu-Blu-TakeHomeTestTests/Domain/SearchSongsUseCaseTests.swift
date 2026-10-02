@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

struct SearchSongsUseCaseTests {
    @Test("Trims the term before asking the repository")
    func trimsTerm() async throws {
        let repository = SpySongRepository(result: .success([.sample(id: 1)]))
        let useCase = SearchSongsUseCaseImpl(repository: repository)

        let songs = try await useCase.search(term: "  coldplay \n")

        #expect(songs == [.sample(id: 1)])
        #expect(await repository.receivedTerms == ["coldplay"])
    }

    @Test("Returns nothing for blank input without calling the repository")
    func skipsBlankTerm() async throws {
        let repository = SpySongRepository(result: .success([.sample(id: 1)]))
        let useCase = SearchSongsUseCaseImpl(repository: repository)

        let songs = try await useCase.search(term: "   ")

        #expect(songs.isEmpty)
        #expect(await repository.receivedTerms.isEmpty)
    }

    @Test("Lets repository errors through")
    func passesErrorsThrough() async {
        let useCase = SearchSongsUseCaseImpl(repository: SpySongRepository(result: .failure(.noConnection)))

        await #expect(throws: AppErrorType.noConnection) {
            try await useCase.search(term: "coldplay")
        }
    }
}

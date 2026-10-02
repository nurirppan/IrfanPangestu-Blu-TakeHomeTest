@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

struct UnwiredSongRepositoryTests {
    @Test("Fails with a message that points to autoRegister()")
    func pointsToAutoRegister() async throws {
        do {
            _ = try await UnwiredSongRepository().searchSongs(term: "coldplay")
            Issue.record("Expected the unwired repository to throw")
        } catch AppErrorType.localError(let message) {
            #expect(message.contains("autoRegister()"))
        }
    }
}

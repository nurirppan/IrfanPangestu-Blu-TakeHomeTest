@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

@MainActor
struct UnwiredNowPlayingRepositoryTests {
    @Test("Reports a message that points to autoRegister(), once")
    func reportsUnwiredRepository() {
        var messages: [String] = []

        let repository = UnwiredNowPlayingRepository { messages.append($0) }
        repository.show(.idle)

        #expect(messages.count == 1)
        #expect(messages.first?.contains("autoRegister()") == true)
    }
}

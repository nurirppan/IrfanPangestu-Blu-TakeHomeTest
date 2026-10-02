import Foundation
@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

@MainActor
struct UnwiredPlayerRepositoryTests {
    @Test("Reports a failure that points to autoRegister()")
    func reportsUnwiredFailure() {
        let repository = UnwiredPlayerRepository()
        var events: [PlayerEventType] = []
        repository.onEvent = { events.append($0) }

        repository.play(url: URL(filePath: "/previews/1.m4a"))

        guard case .failed(.localError(let message)) = events.first else {
            Issue.record("Expected a local error, got \(events)")
            return
        }
        #expect(message.contains("autoRegister()"))
    }
}

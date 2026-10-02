@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

struct AppErrorPresentationModelTests {
    @Test("Errors a retry can fix offer one")
    func retryableErrors() {
        expect(.noConnection, message: "No internet connection", canRetry: true)
        expect(.timeout, message: "The connection is slow, try again", canRetry: true)
        expect(.server(code: 503), message: "Server error (code 503)", canRetry: true)
        expect(.invalidData, message: "Unexpected data from server", canRetry: true)
        expect(.unknown, message: "Something went wrong", canRetry: true)
    }

    @Test("Errors a retry can't fix offer none")
    func finalErrors() {
        expect(.playbackFailed, message: "This song can't be played", canRetry: false)
        expect(.localError(message: "Not wired"), message: "Not wired", canRetry: false)
    }

    private func expect(_ error: AppErrorType, message: String, canRetry: Bool) {
        let model = AppErrorPresentationModel(error: error)

        #expect(model.message == message)
        #expect(model.canRetry == canRetry)
    }
}

import Foundation

/// One table from `AppErrorType` to on-screen text, shared by every screen.
struct AppErrorPresentationModel: Equatable, Sendable {
    let message: String
    let canRetry: Bool

    init(error: AppErrorType) {
        switch error {
        case .noConnection:
            self.init(message: String(localized: "No internet connection"), canRetry: true)
        case .timeout:
            self.init(message: String(localized: "The connection is slow, try again"), canRetry: true)
        case .server(let code):
            self.init(message: String(localized: "Server error (code \(code))"), canRetry: true)
        case .invalidData:
            self.init(message: String(localized: "Unexpected data from server"), canRetry: true)
        case .playbackFailed:
            self.init(message: String(localized: "This song can't be played"), canRetry: false)
        case .localError(let message):
            self.init(message: message, canRetry: false)
        case .unknown:
            self.init(message: String(localized: "Something went wrong"), canRetry: true)
        }
    }

    private init(message: String, canRetry: Bool) {
        self.message = message
        self.canRetry = canRetry
    }
}

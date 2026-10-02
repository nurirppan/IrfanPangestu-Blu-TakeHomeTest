/// The only error a use case throws; the data layer maps every raw error into it exactly once.
enum AppErrorType: Error, Equatable, Sendable {
    case noConnection
    case timeout
    case server(code: Int)
    case invalidData
    case playbackFailed
    case localError(message: String)
    case unknown 
}

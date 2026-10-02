import Foundation

/// Maps raw transport, status and decoding errors to `AppErrorType`, once, at the data boundary.
enum ErrorMapperType {
    static func map(_ error: any Error) -> AppErrorType {
        switch error {
        case let appError as AppErrorType:
            return appError
        case let statusError as HTTPStatusError:
            return .server(code: statusError.statusCode)
        case is DecodingError:
            return .invalidData
        case let urlError as URLError:
            return mapTransport(urlError)
        default:
            return .unknown
        }
    }

    private static func mapTransport(_ error: URLError) -> AppErrorType {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            return .noConnection
        case .timedOut:
            return .timeout
        case .badServerResponse, .cannotParseResponse, .cannotDecodeContentData, .cannotDecodeRawData, .zeroByteResource:
            return .invalidData
        default:
            return .unknown
        }
    }
}

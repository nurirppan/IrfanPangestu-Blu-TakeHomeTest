/// Every state the song list can be in; the view switches over it exhaustively.
enum SongListStateType: Equatable {
    case idle
    case loading
    case loaded([SongModel])
    case empty(term: String)
    case failed(AppErrorType)
}

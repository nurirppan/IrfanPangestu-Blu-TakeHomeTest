/// The system's Now Playing: the lock screen, Control Center and headphone buttons. The data layer implements
/// it with MediaPlayer.
@MainActor
protocol NowPlayingRepository: AnyObject {
    var onCommand: ((RemoteCommandType) -> Void)? { get set }

    /// Shows the state's song, or clears the lock screen when there is none.
    func show(_ state: PlaybackStateModel)
}

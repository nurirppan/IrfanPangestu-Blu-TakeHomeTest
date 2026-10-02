/// Keeps the lock screen and Control Center in step with the player, and plays what their buttons ask for.
@MainActor
protocol NowPlayingUseCase: AnyObject {
    /// Starts following the player; the app calls it once, at launch.
    func start()
}

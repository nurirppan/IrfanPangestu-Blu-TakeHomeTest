import FactoryKit
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    /// The lock screen follows the player from launch; the container's singleton keeps the use case alive.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Container.shared.nowPlayingUseCase().start()
        return true
    }

    /// The generated scene manifest names no delegate class, so the scene delegate is attached here.
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

import UIKit
import AVFoundation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Configure AVAudioSession BEFORE any audio engine or view controller
        configureAudioSession()

        // Create window with navigation controller at root
        let window = UIWindow(windowScene: windowScene)
        let homeVC = HomeViewController()
        let navController = UINavigationController(rootViewController: homeVC)
        window.rootViewController = navController
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Find MainViewController if it's active and save state
        if let nav = window?.rootViewController as? UINavigationController,
           let mainVC = nav.viewControllers.compactMap({ $0 as? MainViewController }).first {
            mainVC.saveState()
            mainVC.getAudioEngine().stop()
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        if let nav = window?.rootViewController as? UINavigationController,
           let mainVC = nav.viewControllers.compactMap({ $0 as? MainViewController }).first {
            mainVC.getAudioEngine().start()
        }
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback)
            try session.setActive(true)
        } catch {
            print("[SceneDelegate] Failed to configure AVAudioSession: \(error)")
        }
    }
}

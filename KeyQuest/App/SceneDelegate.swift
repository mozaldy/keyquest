import UIKit
import AVFoundation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var mainViewController: MainViewController?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Configure AVAudioSession BEFORE any audio engine or view controller
        configureAudioSession()

        // Create window and root VC
        let window = UIWindow(windowScene: windowScene)
        let mainVC = MainViewController()
        self.mainViewController = mainVC
        window.rootViewController = mainVC
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save notes to UserDefaults
        mainViewController?.saveState()
        // Stop audio engine
        mainViewController?.getAudioEngine().stop()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Restart audio engine
        mainViewController?.getAudioEngine().start()
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

import UIKit
import Fetch

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let url = URL(string: "https://f4a4ddde.ngrok.io")!
        let authHandler = AuthHandler()
        
        APIClient.shared.setup(with: Fetch.Config(
            baseURL: url,
            cache: MemoryCache(defaultExpiration: .seconds(60)),
            shouldStub: false))
        
        CredentialsController.shared.resetOnNewInstallations()
        
        return true
    }

    func applicationWillResignActive(_: UIApplication) {
    }

    func applicationDidEnterBackground(_: UIApplication) {
    }

    func applicationWillEnterForeground(_: UIApplication) {
    }

    func applicationDidBecomeActive(_: UIApplication) {
    }

    func applicationWillTerminate(_: UIApplication) {
    }
}

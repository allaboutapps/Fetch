//
//  AppDelegate.swift
//  ReactiveExample
//
//  Created by Matthias Buchetics on 17.04.19.
//  Copyright © 2019 all about apps Gmbh. All rights reserved.
//

import UIKit
import Fetch

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let url = URL(string: "https://f4a4ddde.ngrok.io")!
        
        APIClient.shared.setup(with: Fetch.Config(
            baseURL: url,
            interceptor: AuthHandler(),
            cache: MemoryCache(defaultExpiration: .seconds(60)),
            shouldStub: false))
        
        CredentialsController.shared.resetOnNewInstallations()
        
        return true
    }

}

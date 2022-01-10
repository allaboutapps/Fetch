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
            shouldStub: true))
        
        registerStubs()
        
        CredentialsController.shared.resetOnNewInstallations()
        
        return true
    }

}

private extension AppDelegate {
    
    func registerStubs() {
        let stubProvider = APIClient.shared.stubProvider
        
        let stubAuthResponse = StubResponse(statusCode: 200, fileName: "authresponse.json", delay: 3)
        let stubConditional = ClosureStub { () -> Stub in
            let unauthorizedStub = StubResponse(statusCode: 401, data: Data(), delay: 2)
            let okStub = StubResponse(statusCode: 200, data: Data(), delay: 2)
            return CredentialsController.shared.currentCredentials == nil ? unauthorizedStub : okStub
        }
        let stubAlternating = AlternatingStub(stubs: [
            StubResponse(statusCode: 401, data: Data(), delay: 2),
            StubResponse(statusCode: 200, data: Data(), delay: 2)
        ])
        let stubBlog = StubResponse(statusCode: 200, fileName: "posts.json", delay: 1)
        
        stubProvider.register(stub: stubAuthResponse, for: API.StubbedAuth.login(username: "", password: ""))
        stubProvider.register(stub: stubAuthResponse, for: API.StubbedAuth.tokenRefresh(""))
        stubProvider.register(stub: stubConditional, for: API.StubbedAuth.authorizedRequest())
        stubProvider.register(stub: stubAlternating, for: API.StubbedAuth.unauthorizedErrorRequest())
        
        stubProvider.register(stub: stubBlog, for: API.BlogPosts.list())
    }
}

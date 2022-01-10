//
//  ViewController.swift
//  ReactiveExample
//
//  Created by Matthias Buchetics on 17.04.19.
//  Copyright © 2019 all about apps Gmbh. All rights reserved.
//

import UIKit
import Fetch

class ViewController: UIViewController {
    
    @IBOutlet private var logTextView: UITextView!
    
    private let failingResource: Resource<Data> = API.StubbedAuth.unauthorizedErrorRequest()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let logger = APIClient.shared.config.eventMonitors.first(where: { $0 is APILogger }) as? APILogger
        logger?.customOutputClosure = { [weak self] message in
            self?.logTextView.text += "\n" + message
        }
    }

    @IBAction private func authorize(_ sender: Any) {
        API.StubbedAuth.login(username: "TEST", password: "TEST").request().startWithResult { result in
            let credentials: Credentials?
            switch result {
            case .success(let value):
                credentials = value.model
            case .failure:
                credentials = nil
            }
            CredentialsController.shared.currentCredentials = credentials
        }

    }
    
    @IBAction private func refreshToken(_ sender: Any) {
        failingResource.request().start()
    }
    
    @IBAction private func authenticatedRequest(_ sender: Any) {
        API.StubbedAuth.authorizedRequest().request().start()
    }
    
    @IBAction private func randomRequest(_ sender: Any) {
        API.BlogPosts.list().request().start()
    }
    
    @IBAction private func clearCredentials(_ sender: Any) {
        CredentialsController.shared.currentCredentials = nil
    }
    
    @IBAction private func clearLog(_ sender: Any) {
        logTextView.text.removeAll()
    }
}

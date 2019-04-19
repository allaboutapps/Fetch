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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let logger = APIClient.shared.config.eventMonitors.first(where: { $0 is APILogger }) as? APILogger
        logger?.customOutputClosure = { [weak self] message in
            self?.logTextView.text += "\n" + message
        }
    }

    @IBAction private func authorize(_ sender: Any) {
        API.StubbedAuth.login(username: "TEST", password: "TEST").request { result in
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
        API.StubbedAuth.unauthorizedErrorRequest().request { result in
            
        }
    }
    
    @IBAction private func authenticatedRequest(_ sender: Any) {
        
    }
    
    @IBAction private func randomRequest(_ sender: Any) {
        
    }
    
    @IBAction private func clearLog(_ sender: Any) {
        logTextView.text.removeAll()
    }
}

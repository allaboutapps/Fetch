//
//  SimpleRequestViewController.swift
//  Example
//
//  Created by Oliver Krakora on 09.05.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import UIKit

class SimpleRequestViewController: UIViewController {
    
    @IBOutlet private var loadDataButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /// configure the shared instance of the APIClient
        API.setup()
    }
    
    @IBAction private func loadData(_ sender: Any) {
        loadDataButton.isEnabled = false
        
        API.Basics.organization(with: "allaboutapps").request { [weak self] _ in
            self?.loadDataButton.isEnabled = true
        }
    }
}

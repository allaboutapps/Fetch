//
//  StubViewController.swift
//  Example
//
//  Created by Oliver Krakora on 09.05.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import UIKit
import Fetch

class StubViewController: UIViewController {
    
    @IBOutlet private var alwaysSucceedButton: UIButton!
    
    @IBOutlet private var alwaysFailButton: UIButton!
    
    @IBOutlet private var alternatingStubButton: UIButton!
    
    @IBOutlet private var conditionalStubButton: UIButton!
    
    private var conditionalStubShouldFail: Bool = true
    
    private let alternatingStub: AlternatingStub = {
        let ok = StubResponse(statusCode: 200, data: Data(), delay: 2.0)
        let fail = StubResponse(statusCode: 400, data: Data(), delay: 2.0)
        return AlternatingStub(stubs: [ok, fail])
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        API.setup()
    }
    
    @IBAction private func performSuccessStub(_ sender: Any) {
        let stub = StubResponse(statusCode: 200, data: Data(), delay: 2.0)
        
        alwaysSucceedButton.isEnabled = false
        API.Stubbing.stubbedPerson(with: stub).request { [weak self] _ in
            self?.alwaysSucceedButton.isEnabled = true
        }
    }
    
    @IBAction private func performErrorStub(_ sender: Any) {
        let stub = StubResponse(statusCode: 400, data: Data(), delay: 2.0)
        
        alwaysFailButton.isEnabled = false
        API.Stubbing.stubbedPerson(with: stub).request { [weak self] _ in
            self?.alwaysFailButton.isEnabled = true
        }
    }
    
    @IBAction private func performAlternatingStub(_ sender: Any) {
        alternatingStubButton.isEnabled = false
        API.Stubbing.stubbedPerson(with: alternatingStub).request { [weak self] _ in
            self?.alternatingStubButton.isEnabled = true
        }
    }
    
    @IBAction private func conditionalStubStateDidChange(_ sender: Any) {
        conditionalStubShouldFail = (sender as? UISwitch)?.isOn ?? true
    }
    
    @IBAction private func performConditionalStub(_ sender: Any) {
        conditionalStubButton.isEnabled = false
        let conditionalStub = ClosureStub { [unowned self] in
            let ok = StubResponse(statusCode: 200, data: Data(), delay: 2.0)
            let fail = StubResponse(statusCode: 400, data: Data(), delay: 2.0)
            return self.conditionalStubShouldFail ? fail : ok
        }
        
        API.Stubbing.stubbedPerson(with: conditionalStub).request { [weak self] _ in
            self?.conditionalStubButton.isEnabled = true
        }
    }
}

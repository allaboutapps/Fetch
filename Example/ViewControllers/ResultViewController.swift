//
//  ResultViewController.swift
//  Example
//
//  Created by Oliver Krakora on 18.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import UIKit
import Fetch

extension String: Cacheable {}

class ResultViewController: UIViewController {
    
    @IBOutlet private var usedCachePolicyLabel: UILabel!
    
    @IBOutlet private var didFinishFetchingLabel: UILabel!
    
    @IBOutlet private var resourceValueLabel: UILabel!
    
    private var disposable: RequestToken?
    
    var resource: Resource<String>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usedCachePolicyLabel.text = "\(resource.cachePolicy.flatMap { "\($0)" } ?? "NONE" )"
        didFinishFetchingLabel.text = "NO"
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disposable?.cancel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadData()
    }
    
    private func loadData() {
        disposable = resource.fetch { [weak self] result, didFinish in
            guard let self = self else { return }
            
            self.didFinishFetchingLabel.text = didFinish ? "YES" : "NO"
            
            let fontSize = self.resourceValueLabel.font.pointSize
            
            switch result {
            case .success(let value):
                self.resourceValueLabel.text = value.model
                self.resourceValueLabel.textColor = .black
                self.resourceValueLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
            case .failure(let error):
                self.resourceValueLabel.text = "Error: \(error)"
                self.resourceValueLabel.textColor = .red
                self.resourceValueLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
            }
        }
    }
}

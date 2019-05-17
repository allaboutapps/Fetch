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
    
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet private var resultStackView: UIStackView!
    
    private var disposable: RequestToken?
    
    var viewModel: CacheDemoViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usedCachePolicyLabel.text = "\(viewModel.currentCachePolicy.flatMap { "\($0)" } ?? "NONE" )"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(loadData))
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disposable?.cancel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadData()
    }
    
    private let resultFont = UIFont(name: "CourierNewPSMT", size: 14)
    
    @objc private func loadData() {
        var number = 0
        activityIndicator.isHidden = false
        didFinishFetchingLabel.text = "NO"
        resultStackView.subviews.forEach { $0.removeFromSuperview() }
        disposable = viewModel.createResource().fetch { [weak self] (result, didFinish) in
            guard let self = self else { return }
            number += 1
            self.activityIndicator.isHidden = didFinish
            self.didFinishFetchingLabel.text = didFinish ? "YES" : "NO"
            
            let infoLabel = UILabel(frame: .zero)
            infoLabel.numberOfLines = 0
            infoLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            
            let resultLabel = UILabel(frame: .zero)
            resultLabel.numberOfLines = 0
            resultLabel.font = self.resultFont
            
            switch result {
            case .success(let value):
                let responseText = "\(number). Response from"
                switch value {
                case .cache(_, let isExpired):
                    infoLabel.text = "\(responseText) cache \n\t- expired: \(isExpired)"
                case .network(let response, let updated):
                    infoLabel.text = "\(responseText) network \n\t- status code: \(response.urlResponse.statusCode) \n\t- did response change: \(updated)"
                }
                resultLabel.text = value.model
                resultLabel.textColor = .black
            case .failure(let error):
                resultLabel.text = "Error: \(error)"
                resultLabel.textColor = .red
            }
            self.resultStackView.addArrangedSubview(infoLabel)
            self.resultStackView.addArrangedSubview(resultLabel)
        }
    }
}

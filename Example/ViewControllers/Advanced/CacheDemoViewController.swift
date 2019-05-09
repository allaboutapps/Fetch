//
//  MainViewController.swift
//  Example
//
//  Created by Michael Heinzl on 02.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import UIKit
import Fetch

class CacheDemoViewController: UIViewController {
    
    // MARK: Outlets
    @IBOutlet private var fetchBehaviourSegmentedControl: UISegmentedControl!
    
    @IBOutlet private var scrollView: UIScrollView!
    
    @IBOutlet private var cacheTypeSegmentedControl: UISegmentedControl!
    
    @IBOutlet private var urlToFetchStackView: UIStackView!
    
    @IBOutlet private var delayStackView: UIStackView!
    
    @IBOutlet private var delayTextField: UITextField!
    
    @IBOutlet private var urlToFetchTextField: UITextField!
    
    // MARK: Properties
    
    private var viewModel: CacheDemoViewModel!
    
    private var keyboardAppearObserver: Any!
    
    private var keyboardDisappearObserver: Any!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupKeyboardObserver()
        urlToFetchTextField.delegate = self
        delayTextField.delegate = self
        delayTextField.inputAccessoryView = {
            let toolbar = UIToolbar()
            toolbar.translatesAutoresizingMaskIntoConstraints = false
            let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let item = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
            toolbar.setItems([space, item], animated: false)
            return toolbar
        }()
        
        viewModel = CacheDemoViewModel(fetchBehaviour: FetchBehaviour(rawValue: fetchBehaviourSegmentedControl.selectedSegmentIndex)!,
                                       cacheType: CacheType(rawValue: cacheTypeSegmentedControl.selectedSegmentIndex)!)
        
        fetchBehaviourDidChange()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(keyboardAppearObserver!)
        NotificationCenter.default.removeObserver(keyboardDisappearObserver!)
    }
    
    // MARK: Keyboard
    
    private func setupKeyboardObserver() {
        keyboardAppearObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] notification in
            let beginPoint = notification.userInfo?[UIWindow.keyboardFrameBeginUserInfoKey] as? CGRect ?? .zero
            let endPoint = notification.userInfo?[UIWindow.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
            let height = abs(beginPoint.origin.y - endPoint.origin.y)
            self?.scrollView.contentInset.bottom = height
        }
        
        keyboardDisappearObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main, using: { [weak self] _ in
            self?.scrollView.contentInset.bottom = 0
        })
    }
    
    // MARK: Actions
    
    @IBAction private func cacheTypeDidChange() {
        viewModel.currentCacheType = CacheType(rawValue: cacheTypeSegmentedControl.selectedSegmentIndex)!
    }
    
    @IBAction private func fetchBehaviourDidChange() {
        viewModel.currentFetchBehaviour = FetchBehaviour(rawValue: fetchBehaviourSegmentedControl.selectedSegmentIndex)!
        switch viewModel.currentFetchBehaviour {
        case .stub:
            _ = viewModel.setStubDelay(with: delayTextField.text)
            urlToFetchStackView.isHidden = true
            delayStackView.isHidden = false
            urlToFetchTextField.resignFirstResponder()
        case .fetchFromURL:
            delayTextField.resignFirstResponder()
            // Set url from prefilled textfield
            _ = viewModel.setCustomURL(from: urlToFetchTextField.text)
            delayStackView.isHidden = true
            urlToFetchStackView.isHidden = false
        }
    }
    
    @IBAction private func clearCache() {
        viewModel.clearCache()
    }
    
    private func presentAlertWithFeedback(title: String, message: String) {
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.error)
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: Fetch functions
extension CacheDemoViewController {
    
    private func showResult(with policy: CachePolicy) {
        guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResultViewController") as? ResultViewController else { return }
        
        viewModel.currentCachePolicy = policy
        
        vc.viewModel = viewModel
        
        show(vc, sender: nil)
    }
    
    @IBAction func fetchNetworkOnlyUpdateCache(_ sender: Any) {
        showResult(with: .networkOnlyUpdateCache)
    }
    
    @IBAction private func fetchNetworkOnlyNoCache(_ sender: Any) {
        showResult(with: .networkOnlyNoCache)
    }
    
    @IBAction private func fetchCacheOnly(_ sender: Any) {
        showResult(with: .cacheOnly)
    }
    
    @IBAction private func fetchCacheOrNetworkIfNotFoundOrExpired(_ sender: Any) {
        showResult(with: .cacheFirstNetworkIfNotFoundOrExpired)
    }
    
    @IBAction private func fetchCacheFirstAndNetworkAlways(_ sender: Any) {
        showResult(with: .cacheFirstNetworkAlways)
    }
    
    @IBAction private func fetchCacheFirstNetworkRefresh(_ sender: Any) {
        showResult(with: .cacheFirstNetworkRefresh)
    }
}

extension CacheDemoViewController: UITextFieldDelegate {
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == urlToFetchTextField {
            return shouldURLTextFieldReturn()
        }
        return true
    }
    
    private func shouldURLTextFieldReturn() -> Bool {
        guard viewModel.setCustomURL(from: urlToFetchTextField.text) else {
            presentAlertWithFeedback(title: "No valid url", message: "Please enter a valid url e.g https://example.com/test")
            return false
        }
        urlToFetchTextField.resignFirstResponder()
        return true
    }
    
    private func shouldDelayTextFieldReturn() -> Bool {
        guard viewModel.setStubDelay(with: delayTextField.text) else {
            delayTextField.text = "\(viewModel.fetchDelay)"
            presentAlertWithFeedback(title: "No valid number", message: "Please enter a number greater than 0.0")
            return false
        }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == delayTextField {
            _ = shouldDelayTextFieldReturn()
        }
    }
}

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
    
    // MARK: Type definitions
    enum CacheType: Int {
        case memory = 0
        case disk = 1
        case hybrid = 2
        case none = 3
    }
    
    enum FetchBehaviour: Int {
        case stub = 0
        case fetchFromURL = 1
    }
    
    enum DisplayBehaviour: Int {
        case json = 0
        case rawData = 1
    }
    
    // MARK: Outlets
    @IBOutlet private var fetchBehaviourSegmentedControl: UISegmentedControl!
    
    @IBOutlet private var scrollView: UIScrollView!
    
    @IBOutlet private var displayBehaviourControl: UISegmentedControl!
    
    @IBOutlet private var cacheTypeSegmentedControl: UISegmentedControl!
    
    @IBOutlet private var urlToFetchStackView: UIStackView!
    
    @IBOutlet private var urlToFetchTextField: UITextField!
    
    @IBOutlet private var fetchButtons: [UIButton]!
    
    // MARK: Properties
    
    private var currentCache: Cache? {
        set {
            var config = APIClient.shared.config
            config.cache = newValue
            APIClient.shared.setup(with: config)
        } get {
            return APIClient.shared.config.cache
        }
    }
    
    private var cacheExpiration: Expiration = .seconds(30)
    
    private var customURLComponents: URLComponents?
    
    private var resourceStubPath: String = "/stub"
    
    private var fetchDelay: TimeInterval = 2
    
    private var returnExpiredCacheItems: Bool = true
    
    private var maxDiskCacheSizeInBytes: UInt = 1024
    
    private var keyboardAppearObserver: Any!
    
    private var keyboardDisappearObserver: Any!
    
    private var currentFetchBehaviour: FetchBehaviour {
        return FetchBehaviour(rawValue: fetchBehaviourSegmentedControl.selectedSegmentIndex)!
    }
    
    private var currentDisplayBehaviour: DisplayBehaviour {
        return DisplayBehaviour(rawValue: displayBehaviourControl.selectedSegmentIndex)!
    }
    
    private var currentCacheType: CacheType {
        return CacheType(rawValue: cacheTypeSegmentedControl.selectedSegmentIndex)!
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       keyboardAppearObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] notification in
            let beginPoint = notification.userInfo?[UIWindow.keyboardFrameBeginUserInfoKey] as? CGRect ?? .zero
            let endPoint = notification.userInfo?[UIWindow.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
            let height = abs(beginPoint.origin.y - endPoint.origin.y)
            self?.scrollView.contentInset.bottom = height
        }
        
        keyboardDisappearObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main, using: { [weak self] _ in
            self?.scrollView.contentInset.bottom = 0
        })
        
        urlToFetchTextField.delegate = self
        
        currentCache = createCache()
        fetchBehaviourDidChange()
    }

    deinit {
        NotificationCenter.default.removeObserver(keyboardAppearObserver)
        NotificationCenter.default.removeObserver(keyboardDisappearObserver)
    }
    
    // MARK: Actions
    
    @IBAction private func cacheTypeDidChange() {
        currentCache = createCache()
    }
    
    @IBAction private func fetchBehaviourDidChange() {
        switch currentFetchBehaviour {
        case .stub:
            urlToFetchStackView.isHidden = true
        case .fetchFromURL:
            urlToFetchStackView.isHidden = false
        }
    }
    
    @IBAction private func displayBehaviourDidChange() {
        
    }
}

// MARK: Cache functions
extension CacheDemoViewController {
    
    @IBAction private func clearCache(_ sender: Any) {
        try? currentCache?.removeAll()
    }
    
    private func createCache() -> Cache? {
        switch currentCacheType {
        case .memory: return createMemoryCache()
        case .disk: return createDiskCache()
        case .hybrid: return createCombinedCache()
        case .none: return nil
        }
    }
    
    private func createDiskCache() -> DiskCache {
        let diskCache = try! DiskCache(maxSize: Int(maxDiskCacheSizeInBytes), defaultExpiration: cacheExpiration)
        try? diskCache.removeAll()
        return diskCache
    }
    
    private func createMemoryCache() -> MemoryCache {
        let memoryCache = MemoryCache(defaultExpiration: cacheExpiration, returnIfExpired: returnExpiredCacheItems)
        memoryCache.removeAll()
        return memoryCache
    }
    
    private func createCombinedCache() -> HybridCache {
        let memoryCache = createMemoryCache()
        let diskCache = createDiskCache()
        return HybridCache(primaryCache: memoryCache, secondaryCache: diskCache)
    }
}

// MARK: Fetch functions
extension CacheDemoViewController {
    
    private func createResource(with cachePolicy: CachePolicy) -> Resource<String> {
        
        let client = APIClient.shared
        
        let baseURL = APIClient.shared.config.baseURL
        
        let parameters: [String: Any]? = nil
        
        var stubResponse: StubResponse? {
            guard case .stub = currentFetchBehaviour else { return nil }
            return StubResponse(statusCode: 200, fileName: "post.json", delay: fetchDelay)
        }
        
        return Resource<String>(apiClient: client,
                                baseURL: baseURL,
                                path: resourceStubPath,
                                urlParameters: parameters,
                                cachePolicy: cachePolicy,
                                cacheExpiration: cacheExpiration,
                                shouldStub: stubResponse != nil,
                                stub: stubResponse,
                                decode: { data in
                                    return String(decoding: data, as: UTF8.self)
        })
    }
    
    private func showResult(with policy: CachePolicy) {
        guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResultViewController") as? ResultViewController else { return }
        
        vc.resource = createResource(with: policy)
        
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
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text, !text.isEmpty, let components = URLComponents(string: text) else {
            textField.text = nil
        let notificationGenerator = UINotificationFeedbackGenerator()
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(.error)
            
        let alert = UIAlertController(title: "No valid url", message: "Please enter a valid url", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
            return
        }
        customURLComponents = components
    }
}

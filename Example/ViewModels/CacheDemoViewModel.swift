//
//  CacheDemoViewModel.swift
//  Example
//
//  Created by Oliver Krakora on 19.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Alamofire
import Fetch

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

class CacheDemoViewModel {
    
    var currentFetchBehaviour: FetchBehaviour
    
    var currentCachePolicy: CachePolicy?
    
    var currentCacheType: CacheType {
        didSet {
            currentCache = createCache()
        }
    }
    
    var cacheExpiration: Expiration = .seconds(30)
    
    private(set) var customURLComponents: URLComponents?
    
    var resourceStubPath: String = "/stub"
    
    private(set) var fetchDelay: TimeInterval = 2
    
    var returnExpiredCacheItems: Bool = true
    
    var maxDiskCacheSizeInBytes: UInt = 1024
    
    var currentCache: Cache? {
        set {
            var config = APIClient.shared.config
            config.cache = newValue
            APIClient.shared.setup(with: config)
        } get {
            return APIClient.shared.config.cache
        }
    }
    
    init(fetchBehaviour: FetchBehaviour, cacheType: CacheType) {
        self.currentFetchBehaviour = fetchBehaviour
        self.currentCacheType = cacheType
        self.currentCache = createCache()
    }
}

// MARK: Cache functions
extension CacheDemoViewModel {
    
    func clearCache() {
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
extension CacheDemoViewModel {
 
    func createResource() -> Resource<String> {
        
        let client = APIClient.shared
        
        let baseURL: URL = {
            switch currentFetchBehaviour {
            case .stub: return APIClient.shared.config.baseURL
            case .fetchFromURL:
                var components = customURLComponents!
                components.path = ""
                components.queryItems = nil
                return components.url!
            }
        }()
        
        let parameters: [String: Any]? = {
            guard case .fetchFromURL = currentFetchBehaviour, let components = customURLComponents else { return nil }
            let pairs: [(String, Any)]? = components.queryItems?.map { ($0.name, $0.value as Any) }
            return Dictionary(pairs ?? [], uniquingKeysWith: { first, _ in return first })
        }()
        
        let path: String = {
            guard case .fetchFromURL = currentFetchBehaviour, let components = customURLComponents else { return resourceStubPath }
            return components.path
        }()
        
        var stubResponse: StubResponse? {
            guard case .stub = currentFetchBehaviour else { return nil }
            return StubResponse(statusCode: 200, fileName: "post.json", delay: fetchDelay)
        }
        
        return Resource<String>(apiClient: client,
                                baseURL: baseURL,
                                path: path,
                                urlParameters: parameters,
                                cachePolicy: currentCachePolicy,
                                cacheExpiration: cacheExpiration,
                                shouldStub: stubResponse != nil,
                                stub: stubResponse,
                                decode: { data in
                                    return String(decoding: data, as: UTF8.self)
        })
    }
    
    func setCustomURL(from text: String?) -> Bool {
        guard let text = text, !text.isEmpty, let components = URLComponents(string: text) else { return false }
        customURLComponents = components
        return true
    }
    
    func setStubDelay(with text: String?) -> Bool {
        guard let text = text, !text.isEmpty else { return false }
        guard let interval = TimeInterval(text) else { return false }
        return setStubDelay(in: interval)
    }
    
    func setStubDelay(in seconds: TimeInterval) -> Bool {
        guard seconds >= 0 else { return false }
        fetchDelay = seconds
        return true
    }
}

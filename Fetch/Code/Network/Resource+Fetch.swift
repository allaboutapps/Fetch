//
//  Resource+Fetch.swift
//  Fetch
//
//  Created by Matthias Buchetics on 09.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Fetch

public enum FetchResponse<T> {
    case cache(T, isExpired: Bool)
    case network(response: NetworkResponse<T>, updated: Bool)
    
    public var model: T? {
        switch self {
        case .cache(let model, _):
            return model
        case .network(let networkResponse, _):
            return networkResponse.model
        }
    }
}

public extension Resource where T: Cacheable {
    
//    var cachedEntry: (data: T, isExpired: Bool)? {
//        if let entry: CacheEntry<T> = cache?.get(for: self) {
//            return (data: entry.data, isExpired: entry.isExpired)
//        } else {
//            return nil
//        }
//    }
    
    var cachedValue: T? {
        return cache?.value(for: self)
    }
    
    // MARK: Fetch
    
    @discardableResult func fetch(cachePolicy: CachePolicy? = nil, queue: DispatchQueue = .main, onResponse: @escaping (Swift.Result<FetchResponse<T>, FetchError>, Bool) -> Void) -> RequestToken {
        guard let cache = cache else {
            return requestAndUpdateCache(cache: nil, queue: queue, completion: onResponse)
        }
        
        switch method {
        case .get:
            // use provided cache policy OR resource cache  policy OR default client cache policy
            return fetchUsingCache(cache, cachePolicy: cachePolicy ?? self.cachePolicy ?? apiClient.config.cachePolicy, onResponse: onResponse)
        case .post, .patch, .put, .delete:
            return requestAndUpdateCache(cache: nil, queue: queue) { (result, isFinished) in
                // remove all cache entries that belong to the same groups
                let strongSelf = self
                if let group = strongSelf.cacheGroup {
                    do {
                        try strongSelf.cache?.remove(group: group)
                    } catch {
                        print("cache error: \(error)")
                    }
                }
                
                onResponse(result, isFinished)
            }
        default:
            return requestAndUpdateCache(cache: nil, queue: queue, completion: onResponse)
        }
    }
    
    @discardableResult private func fetchUsingCache(_ cache: Cache, cachePolicy: CachePolicy, queue: DispatchQueue = .main, onResponse: @escaping (Swift.Result<FetchResponse<T>, FetchError>, Bool) -> Void) -> RequestToken {
        
        let token = RequestToken()
        
        switch cachePolicy {
            
        case .networkOnlyNoCache:
            token += requestAndUpdateCache(cache: nil, queue: queue, completion: onResponse)

        case .networkOnlyUpdateCache:
            token += requestAndUpdateCache(cache: cache, queue: queue, completion: onResponse)
            
        case .cacheOnly:
            token += readCacheAsync(queue: queue) { (entry) in
                if let entry = entry {
                    onResponse(.success(.cache(entry.data, isExpired: entry.isExpired)), true)
                } else {
                    onResponse(.failure(.cacheNotFound), true)
                }
            }

        case .cacheFirstNetworkIfNotFoundOrExpired:
            token += readCacheAsync(queue: queue) { (entry) in
                
                if let entry = entry {
                    if entry.isExpired {
                        onResponse(.success(.cache(entry.data, isExpired: true)), false)
                        token += self.requestAndUpdateCache(cache: cache, compareWith: entry.data, queue: queue, completion: onResponse)
                    } else {
                        onResponse(.success(.cache(entry.data, isExpired: false)), true)
                    }
                } else {
                    token += self.requestAndUpdateCache(cache: cache, queue: queue, completion: onResponse)
                }
            }

        case .cacheFirstNetworkAlways:
            token += readCacheAsync(queue: queue) {  (entry) in
                
                if let entry = entry {
                    onResponse(.success(.cache(entry.data, isExpired: entry.isExpired)), false)
                    token += self.requestAndUpdateCache(cache: cache, compareWith: entry.data, queue: queue, completion: onResponse)
                } else {
                    token += self.requestAndUpdateCache(cache: cache, queue: queue, completion: onResponse)
                }
            }

        case .cacheFirstNetworkRefresh:
            token += readCacheAsync(queue: queue) {  (entry) in
                
                if let entry = entry {
                    onResponse(.success(.cache(entry.data, isExpired: entry.isExpired)), true)
                    token += self.requestAndUpdateCache(cache: cache, queue: queue, completion: nil)
                } else {
                    token += self.requestAndUpdateCache(cache: cache, queue: queue, completion: onResponse)
                }
            }
            
        case .networkFirstCacheIfFailed:
            // try network first
            // if success: return network response
            // if error: try cache
            //      if cache success: return cache response
            //      if cache error: return network (not cache) error
            break
        }
        
        return token
    }
    
    private func requestAndUpdateCache(cache: Cache?, compareWith cached: T? = nil, queue: DispatchQueue, completion: ((Swift.Result<FetchResponse<T>, FetchError>, Bool) -> Void)?) -> RequestToken {
        return apiClient.request(self, queue: apiClient.decodingQueue) { (result) in
            if let cache = cache, let data = try? result.get().model {
                do {
                    try cache.set(data, for: self)
                } catch {
                    print("cache set failed: \(error)")
                }
            }
            
            if let completion = completion {
                let fetchResult: Swift.Result<FetchResponse<T>, FetchError> = result.map { (networkResponse) in
                    let isEqual = networkResponse.model.isEqualTo(cached)
                    return .network(response: networkResponse, updated: !isEqual)
                }
                
                queue.async {
                    completion(fetchResult, true)
                }
            }
        }
    }
    
    private func readCacheAsync(queue: DispatchQueue, completion: @escaping (CacheEntry<T>?) -> Void) -> RequestToken {
        let token = RequestToken()
        
        apiClient.decodingQueue.async {
            queue.async {
                if !token.isCancelled {
                    if let entry: CacheEntry<T> = try? self.cache?.get(for: self) {
                        completion(entry)
                    } else {
                        completion(nil)
                    }
                }
            }
        }
        
        return token
    }
}

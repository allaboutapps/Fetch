//
//  Cache.swift
//  Fetch
//
//  Created by Matthias Buchetics on 08.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

public enum CachePolicy {
    case networkOnlyUpdateCache
    case networkOnlyNoCache
    case cacheOnly
    case cacheFirstNetworkIfNotFoundOrExpired
    case cacheFirstNetworkAlways
    case cacheFirstNetworkRefresh
    case networkFirstCacheIfFailed
}

public struct CacheEntry<T: Cacheable> {
    let data: T
    let expirationDate: Date
    
    var isExpired: Bool {
        return expirationDate.timeIntervalSinceNow < 0
    }
}

public protocol Cache {
    func set<T: Cacheable>(_ data: T, for resource: CacheableResource) throws
    func set<T: Cacheable>(_ data: T, expirationDate: Date, for resource: CacheableResource) throws
    func get<T: Cacheable>(for resource: CacheableResource) throws -> CacheEntry<T>?
    
    func remove(for resource: CacheableResource) throws
    func remove(group: String) throws
    func removeExpired() throws
    func removeExpired(olderThan date: Date) throws
    func removeAll() throws
    func cleanup() throws
}

public extension Cache {
    
    func value<T: Cacheable>(for resource: CacheableResource) -> T? {
        return try? get(for: resource)?.data
    }
}

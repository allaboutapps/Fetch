//
//  HybridCache.swift
//  Fetch
//
//  Created by Matthias Buchetics on 16.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

public class HybridCache: Cache {
    
    let primaryCache: Cache
    let secondaryCache: Cache
    
    init(primaryCache: Cache, secondaryCache: Cache) {
        self.primaryCache = primaryCache
        self.secondaryCache = secondaryCache
    }
    
    // MARK: Cache
    
    public func set<T>(_ data: T, for resource: CacheableResource) throws where T: Cacheable {
        try primaryCache.set(data, for: resource)
        try secondaryCache.set(data, for: resource)
    }
    
    public func set<T>(_ data: T, expirationDate: Date, for resource: CacheableResource) throws where T: Cacheable {
        try primaryCache.set(data, expirationDate: expirationDate, for: resource)
        try secondaryCache.set(data, expirationDate: expirationDate, for: resource)
    }
    
    public func get<T>(for resource: CacheableResource) throws -> CacheEntry<T>? where T: Cacheable {
        if let entry: CacheEntry<T> = try? primaryCache.get(for: resource) {
            return entry
        } else if let entry: CacheEntry<T> = try? secondaryCache.get(for: resource) {
            try primaryCache.set(entry.data, expirationDate: entry.expirationDate, for: resource)
            return entry
        } else {
            return nil
        }
    }
    
    public func remove(for resource: CacheableResource) throws {
        try primaryCache.remove(for: resource)
        try secondaryCache.remove(for: resource)
    }
    
    public func remove(group: String) throws {
        try primaryCache.remove(group: group)
        try secondaryCache.remove(group: group)
    }
    
    public func removeExpired() throws {
        try primaryCache.removeExpired()
        try secondaryCache.removeExpired()
    }
    
    public func removeExpired(olderThan date: Date) throws {
        try primaryCache.removeExpired(olderThan: date)
        try secondaryCache.removeExpired(olderThan: date)
    }
    
    public func removeAll() throws {
        try primaryCache.removeAll()
        try secondaryCache.removeAll()
    }
    
    public func cleanup() throws {
        try primaryCache.cleanup()
        try secondaryCache.cleanup()
    }
}

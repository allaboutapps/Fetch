//
//  MemoryCache.swift
//  Fetch
//
//  Created by Matthias Buchetics on 09.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

public class MemoryCache: Cache {
    
    public struct Entry {
        let data: Cacheable
        let group: String?
        let expirationDate: Date
        
        var isExpired: Bool {
            return expirationDate.timeIntervalSinceNow < 0
        }
        
        init(_ data: Cacheable, group: String? = nil, expirationDate: Date) {
            self.data = data
            self.group = group
            self.expirationDate = expirationDate
        }
    }
    
    var cache = [String: Entry]()

    private let defaultExpiration: Expiration
    private let returnIfExpired: Bool
    
    // MARK: Init
    
    public init(defaultExpiration: Expiration = .never, returnIfExpired: Bool = true) {
        self.defaultExpiration = defaultExpiration
        self.returnIfExpired = returnIfExpired
    }
    
    // MARK: Cache
    
    public func set<T: Cacheable>(_ data: T, for resource: CacheableResource) throws {
        let expiration = resource.cacheExpiration ?? defaultExpiration        
        try set(data, expirationDate: expiration.date, for: resource)
    }
    
    public func set<T: Cacheable>(_ data: T, expirationDate: Date, for resource: CacheableResource) throws {
        print("[MemoryCache] set \(resource.cacheKey): \(data)")
        cache[resource.cacheKey] = Entry(data, group: resource.cacheGroup, expirationDate: expirationDate)
    }
    
    public func get<T: Cacheable>(for resource: CacheableResource) throws -> CacheEntry<T>? {
        guard let entry = cache[resource.cacheKey] else {
            print("[MemoryCache] get \(resource.cacheKey): not found")
            return nil
        }
        
        guard let data = entry.data as? T else {
            print("[MemoryCache] get \(resource.cacheKey): invalid type")
            return nil
        }
        
        guard returnIfExpired || entry.isExpired == false else {
            print("[MemoryCache] get \(resource.cacheKey): is expired")
            try? remove(for: resource)
            return nil
        }
        
        print("[MemoryCache] get \(resource.cacheKey): \(data)")
        return CacheEntry(data: data, expirationDate: entry.expirationDate)
    }
    
    public func remove(for resource: CacheableResource) throws {
        print("[MemoryCache] remove \(resource.cacheKey)")
        
        cache.removeValue(forKey: resource.cacheKey)
    }
    
    public func remove(group: String) throws {
        cache
            .filter { $0.value.group == group }
            .forEach { (key, _) in
                print("[MemoryCache] remove \(key)")
                self.cache.removeValue(forKey: key)
            }
    }
    
    public func removeExpired() throws {
        cache
            .filter { $0.value.isExpired }
            .forEach { (key, _) in
                print("[MemoryCache] remove \(key)")
                self.cache.removeValue(forKey: key)
            }
    }
    
    public func removeExpired(olderThan date: Date) throws {
        cache
            .filter { $0.value.expirationDate < date }
            .forEach { (key, _) in
                print("[MemoryCache] remove \(key)")
                self.cache.removeValue(forKey: key)
            }
    }
    
    public func removeAll() {
        cache.removeAll()
    }
    
    public func cleanup() throws {
        try removeExpired()
    }
}

//
//  Cacheable.swift
//  Fetch
//
//  Created by Matthias Buchetics on 15.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

public protocol Cacheable: Codable {
    func isEqualTo(_ other: Cacheable?) -> Bool
}

public protocol CacheableResource {
    var cacheKey: String { get }
    var cacheGroup: String? { get }
    var cacheExpiration: Expiration? { get }
}

// MARK: Extensions

public extension Cacheable where Self: Equatable {
    
    func isEqualTo(_ other: Cacheable?) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
    }
}

extension Array: Cacheable where Element: Cacheable {
    
    public func isEqualTo(_ other: Cacheable?) -> Bool {
        guard let other = other as? [Element] else { return false }
        
        let isDifferent = zip(self, other).contains {
            !$0.0.isEqualTo($0.1)
        }
        
        return !isDifferent
    }
}

//
//  HybridCacheTests.swift
//  FetchTests
//
//  Created by Matthias Buchetics on 09.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import XCTest
import Alamofire

@testable
import Fetch

class HybridCacheTests: CacheTests {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    override func createCache() -> Cache {
        let memoryCache = MemoryCache(defaultExpiration: .seconds(10.0))
        let diskCache = try! DiskCache(name: "at.allaboutapps.HybridCacheTest", defaultExpiration: .seconds(60.0))
        
        let cache = HybridCache(primaryCache: memoryCache, secondaryCache: diskCache)
        try! cache.removeAll()
        return cache
    }
}

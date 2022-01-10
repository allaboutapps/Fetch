//
//  CacheTests.swift
//  FetchTests
//
//  Created by Matthias Buchetics on 09.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import XCTest
import Alamofire

@testable
import Fetch

class DiskCacheTests: CacheTests {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    override func createCache() -> Cache {
        let cache = try! DiskCache(name: "at.allaboutapps.DiskCacheTest", defaultExpiration: .seconds(60.0))
        try! cache.removeAll()
        return cache
    }
    
    func testCleanup() {
        let maxSize = 1000
        let cache = try! DiskCache(maxSize: 1000)
        
        struct Resource: CacheableResource {
            let cacheKey: String
            let cacheGroup: String? = nil
            let cacheExpiration: Expiration? = .never
        }
        
        for index in 0 ..< 1000 {
            let r = Resource(cacheKey: "\(index)")
            try! cache.set(ModelA(a: "\(index)"), for: r)
        }
        
        print(try! cache.computeTotalSize())
        
        try! cache.cleanup()
        
        print(try! cache.computeTotalSize())
        
        XCTAssert(try! cache.computeTotalSize() < maxSize, "cache size should be less than maximum")
    }
    
    func testFileExistence() {
        let resource = Resource<ModelA>(
            apiClient: client,
            path: "/test"
        )
        
        let diskCache = resource.cache as? DiskCache
        
        XCTAssertNotNil(diskCache)
        
        let model = ModelA(a: "abcdefg")
        
        try? diskCache?.set(model, for: resource)
        
        let path = diskCache!.path(for: resource)
        
        let exists = FileManager.default.fileExists(atPath: path)
        
        XCTAssertTrue(exists)
    }
    
    func testFileExistenceAfterDelete() {
        let resource = Resource<ModelA>(
            apiClient: client,
            path: "/test"
        )
        
        let diskCache = resource.cache as? DiskCache
        
        XCTAssertNotNil(diskCache)
        
        let model = ModelA(a: "abcdefg")
        
        try? diskCache?.set(model, for: resource)
        
        let path = diskCache!.path(for: resource)
        
        try? diskCache?.remove(for: resource)
        
        let exists = FileManager.default.fileExists(atPath: path)
        
        XCTAssertFalse(exists)
    }
}

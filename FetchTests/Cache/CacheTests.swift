//
//  CacheTests.swift
//  FetchTests
//
//  Created by Oliver Krakora on 16.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

@testable
import Fetch
import XCTest

typealias Result = Swift.Result

extension String: Cacheable {}

class CacheTests: XCTestCase {
    
    private(set) var client: APIClient!
    private var cache: Cache!
    
    override func setUp() {
        super.setUp()
        cache = createCache()
        client = createAPIClient()
    }
    
    func createCache() -> Cache {
        return MemoryCache(defaultExpiration: .seconds(10.0))
    }
    
    func createAPIClient() -> APIClient {
        let config = Config(
            baseURL: URL(string: "https://www.asdf.at")!,
            cache: cache,
            shouldStub: true
        )
        
        return APIClient(config: config)
    }
    
    func testEqualCachingKeys() {
        let resourceA = Resource<ModelA>(
            apiClient: client,
            method: .get,
            path: "/test",
            urlParameters: [
                "A": 123,
                "B": 456
            ])
        
        let resourceB = Resource<ModelA>(
            apiClient: client,
            method: .get,
            path: "/test",
            urlParameters: [
                "B": 456,
                "A": 123
            ])
        
        XCTAssert(resourceA.cacheKey == resourceB.cacheKey, "Cache keys should be equal")
    }
    
    func testNonEqualCachingKeys() {
        let resourceA = Resource<ModelA>(
            apiClient: client,
            method: .get,
            path: "/test/detail")
        
        let resourceB = Resource<ModelA>(
            apiClient: client,
            method: .get,
            path: "/test")
        
        XCTAssert(resourceA.cacheKey != resourceB.cacheKey, "Cache keys should be not be equal")
    }
    
    func testCacheOnlyPolicyFailure() {
        let resource = Resource<ModelA>(
            apiClient: client,
            method: .get,
            path: "/test/detail",
            cachePolicy: .cacheOnly)
        
        let expectation = self.expectation(description: "")
        
        resource.fetch { (result, isFinished) in
            expectation.fulfill()
            
            XCTAssert(isFinished == true, "should be finished")
            
            switch result {
            case .failure(.cacheNotFound):
                break
            default:
                XCTFail("should be cacheNotFound failure")
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCacheOnlyPolicySuccess() {
        let resource = Resource<ModelA>(
            apiClient: client,
            method: .get,
            path: "/test/detail",
            cachePolicy: .cacheOnly)
        
        try! resource.cache?.set(ModelA(a: "123"), for: resource)
        
        let expectation = self.expectation(description: "")
        
        resource.fetch { (result, isFinished) in
            expectation.fulfill()
            
            XCTAssert(isFinished == true, "should be finished")
            
            switch result {
            case let .success(.cache(value, _)):
                XCTAssert(value == ModelA(a: "123"), "should be cached value")
            default:
                XCTFail("should not be a failure")
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testNetworkOnlyPolicy() {
        let resource = Resource<ModelA>(
            apiClient: client,
            method: .get,
            path: "/test/detail",
            cachePolicy: .networkOnlyNoCache,
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "123"), encoder: client.config.encoder, delay: 0.1))
        
        let expectation = self.expectation(description: "")
        
        resource.fetch { (result, isFinished) in
            expectation.fulfill()
            
            XCTAssert(isFinished == true, "should be finished")
            
            switch result {
            case let .success(.network(response, _)):
                XCTAssert(response.model == ModelA(a: "123"), "should be network value")
            default:
                XCTFail("should be network value")
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCacheFirstNetworkAlwaysPolicyWithUnchangedCache() {
        let resource = Resource<ModelA>(
            apiClient: client,
            method: .get,
            path: "/test/detail",
            cachePolicy: .cacheFirstNetworkAlways,
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "123"), encoder: client.config.encoder, delay: 0.1))
        
        try! resource.cache?.set(ModelA(a: "123"), for: resource)
        
        let expectation = self.expectation(description: "")
        
        resource.fetch { (result, isFinished) in
            if isFinished == false {
                switch result {
                case let .success(.cache(value, _)):
                    XCTAssert(value == ModelA(a: "123"), "first value should be from cache")
                default:
                    XCTFail("first value should be from cache")
                }
            } else {
                switch result {
                case let .success(.network(_, updated)):
                    XCTAssertEqual(updated, false)
                default:
                    XCTFail("second value should be from network but unchanged from cache")
                }
                
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCacheFirstNetworkAlwaysPolicyWithChangedCache() {
        let resource = Resource<ModelA>(
            apiClient: client,
            method: .get,
            path: "/test/detail",
            cachePolicy: .cacheFirstNetworkAlways,
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "456"), encoder: client.config.encoder, delay: 0.1))
        
        try! resource.cache?.set(ModelA(a: "123"), for: resource)
        
        let expectation = self.expectation(description: "")
        
        resource.fetch { (result, isFinished) in
            if isFinished == false {
                switch result {
                case let .success(.cache(value, _)):
                    XCTAssert(value == ModelA(a: "123"), "first value should be from cache")
                default:
                    XCTFail("first value should be from cache")
                }
            } else {
                switch result {
                case let .success(.network(response, _)):
                    XCTAssert(response.model == ModelA(a: "456"), "second value should be from network")
                default:
                    XCTFail("second value should be from network")
                }
                
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCacheFirstNetworkIfNotFoundOrExpired1() {
        let resource = Resource<ModelA>(
            apiClient: client,
            method: .get,
            path: "/test/detail",
            cachePolicy: .cacheFirstNetworkIfNotFoundOrExpired,
            cacheExpiration: .seconds(-1.0),
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "456"), encoder: client.config.encoder, delay: 0.1))
        
        try! resource.cache?.set(ModelA(a: "123"), for: resource)
        
        let expectation = self.expectation(description: "")
        
        resource.fetch { (result, isFinished) in
            if isFinished == false {
                switch result {
                case let .success(.cache(value, isExpired)):
                    XCTAssert(value == ModelA(a: "123") && isExpired, "first value should be from cache, but is expired")
                default:
                    XCTFail("first value should be from cache, but is expired")
                }
            } else {
                switch result {
                case let .success(.network(response, _)):
                    XCTAssert(response.model == ModelA(a: "456"), "second value should be from network")
                default:
                    XCTFail("second value should be from network")
                }
                
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCacheFirstNetworkIfNotFoundOrExpired2() {
        let resource = Resource<ModelA>(
            apiClient: client,
            method: .get,
            path: "/test/detail",
            cachePolicy: .cacheFirstNetworkIfNotFoundOrExpired,
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "456"), encoder: client.config.encoder, delay: 0.1))
        
        try! resource.cache?.set(ModelA(a: "123"), for: resource)
        
        let expectation = self.expectation(description: "")
        
        resource.fetch { (result, _) in
            switch result {
            case let .success(.cache(value, isExpired)):
                XCTAssert(value == ModelA(a: "123") && !isExpired, "value should be from cache, not expired and finished")
            default:
                XCTFail("value should be from cache, not expired and finished")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCacheSetter() {
        let resource = Resource<ModelA>(
            apiClient: client,
            method: .get,
            path: "/test/detail",
            cachePolicy: .cacheFirstNetworkIfNotFoundOrExpired,
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "456"), encoder: client.config.encoder, delay: 0.1))
        
        let expectation = self.expectation(description: "")
        
        resource.fetch { (result, isFinished) in
            switch result {
            case let .success(.network(response, _)):
                XCTAssert(response.model == ModelA(a: "456") && isFinished, "value should be from network and finished")
            default:
                XCTFail("value should be from network and finished")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            resource.fetch { (result, isFinished) in
                switch result {
                case let .success(.cache(value, isExpired)):
                    XCTAssert(value == ModelA(a: "456") && !isExpired && isFinished, "value should be from cache, not expired and finished")
                default:
                    XCTFail("value should be from cache, not expired and finished")
                }
                
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCacheGroups() {
        let cache = MemoryCache()
        
        struct Resource: CacheableResource {
            var cacheExpiration: Expiration?
            
            let cacheKey: String
            let cacheGroup: String?
        }
        
        let r1 = Resource(cacheExpiration: .never, cacheKey: "A", cacheGroup: "a")
        let r2 = Resource(cacheExpiration: .never, cacheKey: "B", cacheGroup: "a")
        let r3 = Resource(cacheExpiration: .never, cacheKey: "C", cacheGroup: "b")
        
        try! cache.set("A", for: r1)
        try! cache.set("B", for: r2)
        try! cache.set("C", for: r3)
        
        try! cache.remove(group: "a")
        
        let v1: String? = cache.value(for: r1)
        let v2: String? = cache.value(for: r2)
        let v3: String? = cache.value(for: r3)
        
        XCTAssert(v1 == nil)
        XCTAssert(v2 == nil)
        XCTAssert(v3 != nil)
    }
    
    func testCacheInvalidationUsingRequest() {
        let resourceGet = Resource<ModelA>(
            apiClient: client,
            method: .get,
            path: "/test",
            cachePolicy: .cacheFirstNetworkAlways,
            cacheGroup: "test",
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "456"), encoder: client.config.encoder, delay: 0.1))
        
        let resourcePost = Resource<ModelA>(
            apiClient: client,
            method: .post,
            path: "/test",
            cacheGroup: "test",
            stub: StubResponse(statusCode: 200, data: Data(), delay: 0.1))
        
        let expectation = self.expectation(description: "")
        
        resourceGet.fetch { (_, _) in
            XCTAssert(resourceGet.cachedValue == ModelA(a: "456"), "value should be in cache")
            
            resourcePost.request { _ in
                XCTAssert(resourceGet.cachedValue == nil, "value should not be in cache anymore")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCacheInvalidationUsingFetch() {
        let resourceGet = Resource<ModelA>(
            apiClient: client,
            method: .get,
            path: "/test",
            cachePolicy: .cacheFirstNetworkAlways,
            cacheGroup: "test",
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "456"), encoder: client.config.encoder, delay: 0.1))
        
        let resourcePost = Resource<ModelA>(
            apiClient: client,
            method: .post,
            path: "/test",
            cacheGroup: "test",
            stub: StubResponse(statusCode: 200, data: Data(), delay: 0.1))
        
        let expectation = self.expectation(description: "")
        
        resourceGet.fetch { (_, _) in
            XCTAssert(resourceGet.cachedValue == ModelA(a: "456"), "value should be in cache")
            
            resourcePost.fetch { (_, _) in
                XCTAssert(resourceGet.cachedValue == nil, "value should not be in cache anymore")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testRemoveExpiredEntries() {
        let fetchAExpectation = expectation(description: "FetchA")
        let fetchBExpectation = expectation(description: "FetchB")
        
        let resourceA = Resource<ModelA>(
            apiClient: client,
            path: "/test",
            cachePolicy: .networkOnlyUpdateCache,
            cacheExpiration: .seconds(-1),
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "912"), encoder: client.config.encoder, delay: 0.1)
        )
        
        let resourceB = Resource<ModelA>(
            apiClient: client,
            path: "/test1",
            cachePolicy: .networkOnlyUpdateCache,
            cacheExpiration: .seconds(10),
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "789"), encoder: client.config.encoder, delay: 0.1)
        )
        
        resourceA.fetch { _, _ in
            fetchAExpectation.fulfill()
        }
        
        resourceB.fetch { _, _ in
            fetchBExpectation.fulfill()
        }
        
        wait(for: [fetchAExpectation, fetchBExpectation], timeout: 2)
        
        var valueA: CacheEntry<ModelA>? = try? cache.get(for: resourceA)
        
        XCTAssertNotNil(valueA)
        
        XCTAssertTrue(valueA!.isExpired)
        
        var valueB: CacheEntry<ModelA>? = try? cache.get(for: resourceB)
        
        XCTAssertNotNil(valueB)
        
        XCTAssertFalse(valueB!.isExpired)
        
        try? cache.removeExpired()
        
        valueA = try? cache.get(for: resourceA)
        
        XCTAssertNil(valueA)
        
        valueB = try? cache.get(for: resourceB)
        
        XCTAssertNotNil(valueB)
    }
    
    func testRemoveEntry() {
        let fetchAExpectation = expectation(description: "FetchA")
        
        let resourceA = Resource<ModelA>(
            apiClient: client,
            path: "/test",
            cachePolicy: .networkOnlyUpdateCache,
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "366"), encoder: client.config.encoder, delay: 0.1)
        )
        
        resourceA.fetch { _, _ in
            fetchAExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
        
        var valueA: CacheEntry<ModelA>? = try? cache.get(for: resourceA)
        
        XCTAssertNotNil(valueA)
        
        try? cache.remove(for: resourceA)
        
        valueA = try? cache.get(for: resourceA)
        
        XCTAssertNil(valueA)
    }
    
    func testCacheFirstNetworkRefreshWithNonEmptyCache() {
        let delay: TimeInterval = 1
        let fetchExpectation = expectation(description: "Wait for fetch")
        
        let networkModel = ModelA(a: "LOADED FROM NETWORK")
        
        let cacheModel = ModelA(a: "STORED IN CACHE")
        
        let resource = Resource<ModelA>(
            apiClient: client,
            path: "/test",
            cachePolicy: .cacheFirstNetworkRefresh,
            stub: StubResponse(statusCode: 200, encodable: networkModel, encoder: client.config.encoder, delay: delay)
        )
        
        try? resource.cache?.set(cacheModel, for: resource)
        
        XCTAssertNotNil(resource.cachedValue)
        
        resource.fetch { result, isFinished in
            XCTAssertTrue(isFinished)
            switch result {
            case .success:
                fetchExpectation.fulfill()
            case .failure:
                break
            }
        }
        
        waitForExpectations(timeout: delay * 2, handler: nil)
        
        let waitForCacheValue = expectation(description: "wait for cache")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay * 2, execute: {
            waitForCacheValue.fulfill()
        })
        
        waitForExpectations(timeout: delay * 2, handler: nil)
        
        let cachedValue: CacheEntry<ModelA>? = try? resource.cache?.get(for: resource)
        
        XCTAssertNotNil(cachedValue)
        
        XCTAssertEqual(networkModel, cachedValue!.data)
    }
    
    func testCacheFirstNetworkRefreshWithEmptyCache() {
        let delay: TimeInterval = 1
        let fetchExpectation = expectation(description: "Wait for fetch")
        
        let networkModel = ModelA(a: "LOADED FROM NETWORK")
        
        let resource = Resource<ModelA>(
            apiClient: client,
            path: "/test",
            cachePolicy: .cacheFirstNetworkRefresh,
            stub: StubResponse(statusCode: 200, encodable: networkModel, encoder: client.config.encoder, delay: delay)
        )
        
        resource.fetch { result, isFinished in
            XCTAssertTrue(isFinished)
            switch result {
            case .success:
                fetchExpectation.fulfill()
            case .failure:
                break
            }
        }
        
        waitForExpectations(timeout: delay * 2, handler: nil)
        
        let cachedValue: CacheEntry<ModelA>? = try? resource.cache?.get(for: resource)
        
        XCTAssertNotNil(cachedValue)
    }
    
    func testClearCache() {
        
        let resourceA = Resource<ModelA>(
            apiClient: client,
            path: "a")
        let resourceB = Resource<ModelA>(
            apiClient: client,
            path: "b")
        let resourceC = Resource<ModelA>(
            apiClient: client,
            path: "c")
        
        try? cache.set(ModelA(a: "qisa0d90912"), for: resourceA)
        try? cache.set(ModelA(a: "aspdi90qiedkpqaw"), for: resourceB)
        try? cache.set(ModelA(a: "s0ßdi23qdküsadasd"), for: resourceC)
        
        var entryA: CacheEntry<ModelA>? {
            return try? cache.get(for: resourceA)
        }
        
        var entryB: CacheEntry<ModelA>? {
            return try? cache.get(for: resourceB)
        }
        
        var entryC: CacheEntry<ModelA>? {
            return try? cache.get(for: resourceC)
        }
        
        XCTAssertNotNil(entryA)
        XCTAssertNotNil(entryB)
        XCTAssertNotNil(entryC)
        
        try! cache.removeAll()
        
        XCTAssertNil(entryA)
        XCTAssertNil(entryB)
        XCTAssertNil(entryC)
    }
    
    func testDeleteCacheWithDate() {
        
        let now = Date()
        
        let resourceA = Resource<ModelA>(
            apiClient: client,
            path: "a",
            cacheExpiration: .seconds(1 * 3600 * 24)
        )
        
        // Expired 24 hours ago
        let resourceB = Resource<ModelA>(
            apiClient: client,
            path: "b",
            cacheExpiration: .seconds(-1 * 3600 * 24)
        )
        
        // Expired 48 hours ago
        let resourceC = Resource<ModelA>(
            apiClient: client,
            path: "c",
            cacheExpiration: .seconds(-1 * 3600 * 48)
        )
        
        try? cache.set(ModelA(a: "a"), for: resourceA)
        try? cache.set(ModelA(a: "b"), for: resourceB)
        try? cache.set(ModelA(a: "c"), for: resourceC)
        
        var entryA: CacheEntry<ModelA>? {
            return try? cache.get(for: resourceA)
        }
        
        var entryB: CacheEntry<ModelA>? {
            return try? cache.get(for: resourceB)
        }
        
        var entryC: CacheEntry<ModelA>? {
            return try? cache.get(for: resourceC)
        }
        
        let dayAgo = Calendar.current.date(byAdding: DateComponents(hour: -24), to: now)!
        
        // Remove values older then 24 hours
        try? cache.removeExpired(olderThan: dayAgo)
        
        XCTAssertNotNil(entryA)
        XCTAssertNotNil(entryB)
        XCTAssertNil(entryC)
        
        // Remove values older then now
        try? cache.removeExpired(olderThan: now)
        
        XCTAssertNil(entryB)
        XCTAssertNotNil(entryA)
        
        let tomorrowPlusOneHour = Calendar.current.date(byAdding: DateComponents(hour: 25), to: now)!
        
        try? cache.removeExpired(olderThan: tomorrowPlusOneHour)
        
        XCTAssertNil(entryA)
        XCTAssertNil(entryB)
        XCTAssertNil(entryC)
    }
    
    func testMalformedFetch() {
        let waitForCompletion = expectation(description: "Wait for completion")
        
        let resource = Resource<ModelA>(
            apiClient: client,
            path: "/a",
            stub: StubResponse(statusCode: 200, encodable: ModelB(b: "asdaskdajs"), encoder: client.config.encoder, delay: 0)
        )
        
        resource.fetch(cachePolicy: .cacheFirstNetworkIfNotFoundOrExpired) { result, _ in
            switch result {
            case .failure:
                waitForCompletion.fulfill()
            case .success:
                break
            }
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
}

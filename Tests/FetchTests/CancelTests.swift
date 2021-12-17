//
//  CancelTests.swift
//  FetchTests
//
//  Created by Michael Heinzl on 11.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import XCTest
import Alamofire
import Fetch

class CancelTests: XCTestCase {
    
    override func setUp() {
        APIClient.shared.setup(with: Config(
            baseURL: URL(string: "https://www.asdf.at")!,
            cache: MemoryCache(),
            shouldStub: true
        ))
    }
    
    func testRequestTokenCanCancelRequest() {
        let expectation = self.expectation(description: "T")
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test")
        
        APIClient.shared.stubProvider.register(stub: StubResponse(statusCode: 200, encodable: ModelA(a: "a"), delay: 0.2), for: resource)
        
        guard let stub = APIClient.shared.stubProvider.stub(for: resource) else {
            XCTFail("Resource has no stub")
            return
        }
        var result: Swift.Result<NetworkResponse<ModelA>, FetchError>?
        let requestToken = resource.request {
            result = $0
        }
        
        guard let token = requestToken else {
            XCTFail("token is nil")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + stub.delay - 0.1) {
            token.cancel()
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + stub.delay + 0.1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
        XCTAssert((try? result?.get()) == nil, "Result value should be nil, becauce request was canceled")
        XCTAssert(token.isCancelled, "Token should be caneled")
    }
    
    func testRequestTokenCanCancelCacheRead() {
        let expectation = self.expectation(description: "T")
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test",
            cachePolicy: .cacheFirstNetworkAlways)
        
        APIClient.shared.stubProvider.register(stub: StubResponse(statusCode: 200, encodable: ModelA(a: "a"), delay: 0.2), for: resource)
        
        guard let stub = APIClient.shared.stubProvider.stub(for: resource) else {
            XCTFail("Resource has no stub")
            return
        }
        
        guard let cache = resource.cache else {
            XCTFail("cache is nil")
            return
        }
        
        do {
            try cache.set(ModelA(a: "a"), for: resource)
        } catch {
            XCTFail("cache set failed")
        }
        
        let token = resource.fetch { (_, _) in
            XCTFail("callback should never be called")
        }
        
        token.cancel()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + stub.delay + 0.1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
        XCTAssert(token.isCancelled, "Token should be caneled")
    }
    
    func testRequestTokenCanCancelDelayed() {
        let expectation = self.expectation(description: "T")
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test",
            cachePolicy: .cacheFirstNetworkAlways)
        
        APIClient.shared.stubProvider.register(stub: StubResponse(statusCode: 200, encodable: ModelA(a: "a"), delay: 0.2), for: resource)
        
        guard let stub = APIClient.shared.stubProvider.stub(for: resource) else {
            XCTFail("Resource has no stub")
            return
        }
        
        guard let cache = resource.cache else {
            XCTFail("cache is nil")
            return
        }
        
        do {
            try cache.set(ModelA(a: "a"), for: resource)
        } catch {
            XCTFail("cache set failed")
        }
        
        let token = resource.fetch { (result, _) in
            switch result {
            case .success(.cache):
                break
            default:
                print("fail")
                XCTFail("callback should only be called once with the cached value, network request should be cancelled")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + stub.delay - 0.1) {
            print("cancel")
            token.cancel()
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + stub.delay + 0.1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10, handler: nil)
        XCTAssert(token.isCancelled, "Token should be caneled")
    }

}

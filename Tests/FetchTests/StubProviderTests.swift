//
//  StubProviderTests.swift
//  FetchTests
//
//  Created by Stefan Wieland on 09.12.21.
//  Copyright © 2021 aaa - all about apps GmbH. All rights reserved.
//

import XCTest
import Fetch

class StubProviderTests: XCTestCase {

    override func setUp() {
        APIClient.shared.setup(with: Config(
            baseURL: URL(string: "https://www.asdf.at")!,
            shouldStub: true
        ))
        APIClient.shared.stubProvider.removeAll()
    }
    
    func testChangeStubForSameResource() {
        let resource = Resource<ModelA>(method: .get, path: "/test")
        
        let expectationA = self.expectation(description: "Fetch model a")
        let stubA = StubResponse(statusCode: 200, encodable: ModelA(a: "a"), delay: 0.1)
        
        APIClient.shared.stubProvider.register(stub: stubA, for: resource)
        
        resource.request { (result) in
            switch result {
            case let .success(value):
                XCTAssertEqual(value.model.a, "a")
                expectationA.fulfill()
            default:
                XCTFail("Request did not return value")
            }
            
        }
        
        // update stub
        wait(for: [expectationA], timeout: 5)
        let expectationB = self.expectation(description: "Fetch model b")
        let stubB = StubResponse(statusCode: 200, encodable: ModelA(a: "b"), delay: 0.1)
        APIClient.shared.stubProvider.register(stub: stubB, for: resource)
        
        resource.request { (result) in
            switch result {
            case let .success(value):
                XCTAssertEqual(value.model.a, "b")
                expectationB.fulfill()
            default:
                XCTFail("Request did not return value")
            }
        }
        
        wait(for: [expectationB], timeout: 5)
    }
    
    func testRemoveStub() {
        let expectation = self.expectation(description: "Fetch model")
        
        let resource = Resource<ModelA>(method: .get, path: "/test")
        
        let stub = StubResponse(statusCode: 200, encodable: ModelA(a: "a"), delay: 0.1)
        APIClient.shared.stubProvider.register(stub: stub, for: resource)
        APIClient.shared.stubProvider.removeStub(for: resource)
        
        resource.request { (result) in
            switch result {
            case .success:
                XCTFail("No stub data expected")
            case .failure(let error):
                XCTAssertNotNil(error, "Expected an error for no valid response")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRemoveStubFromResource() {
        let expectation = self.expectation(description: "Fetch model")
        
        let resource = Resource<ModelA>(method: .get, path: "/test", stubKey: "Foo")
        
        let stub = StubResponse(statusCode: 200, encodable: ModelA(a: "a"), delay: 0.1)
        APIClient.shared.stubProvider.register(stub: stub, forStubKey: "Foo")
        APIClient.shared.stubProvider.removeStub(for: resource)
        
        resource.request { (result) in
            switch result {
            case .success:
                XCTFail("No stub data expected")
            case .failure(let error):
                XCTAssertNotNil(error, "Expected an error for no valid response")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testPOSTStub() {
        let expectationGET = self.expectation(description: "GET model")
        let expectationPOST = self.expectation(description: "POST model")
        
        let resourceGET = Resource<ModelA>(method: .get, path: "/test")
        let resourcePOST = Resource<ModelA>(method: .post, path: "/test")
        
        let stubGET = StubResponse(statusCode: 200, encodable: ModelA(a: "get"), delay: 0.1)
        APIClient.shared.stubProvider.register(stub: stubGET, for: resourceGET)
        
        let stubPOST = StubResponse(statusCode: 200, encodable: ModelA(a: "post"), delay: 0.1)
        APIClient.shared.stubProvider.register(stub: stubPOST, for: resourcePOST)
        
        resourceGET.request { (result) in
            switch result {
            case let .success(value):
                XCTAssertEqual(value.model.a, "get")
            default:
                XCTFail("Request did not return value")
            }
            expectationGET.fulfill()
        }
        
        resourcePOST.request { (result) in
            switch result {
            case let .success(value):
                XCTAssertEqual(value.model.a, "post")
            default:
                XCTFail("Request did not return value")
            }
            expectationPOST.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCustomStubKey() {
        let expectation = self.expectation(description: "GET model")
        
        let resource = Resource<ModelA>(method: .get, path: "/test", stubKey: "key")
        let stub = StubResponse(statusCode: 200, encodable: ModelA(a: "a"), delay: 0.1)
        APIClient.shared.stubProvider.register(stub: stub, forStubKey: "key")
        
        resource.request { (result) in
            switch result {
            case let .success(value):
                XCTAssertEqual(value.model.a, "a")
            default:
                XCTFail("Request did not return value")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
        
}

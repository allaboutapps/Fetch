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
            baseURL: URL(string: "https://www.asdf.at")!
        ))
    }

    func testChangeStubForSameResource() {
        let expectation1 = self.expectation(description: "Fetch model")
        
        let resource = Resource<ModelA>(method: .get, path: "/test")
        
        let stubA = StubResponse(statusCode: 200, encodable: ModelA(a: "a"), delay: 0.1)
        
        APIClient.shared.stubProvider.register(stub: stubA, for: resource)
        
        resource.request { (result) in
            switch result {
            case let .success(value):
                XCTAssertEqual(value.model.a, "a")
                expectation1.fulfill()
            default:
                XCTFail("Request did not return value")
            }
        }
        
        let expectation2 = self.expectation(description: "Fetch model")
        
        let stubB = StubResponse(statusCode: 200, encodable: ModelA(a: "b"), delay: 0.1)
        
        APIClient.shared.stubProvider.register(stub: stubB, for: resource)
        
        resource.request { (result) in
            switch result {
            case let .success(value):
                XCTAssertEqual(value.model.a, "b")
                expectation2.fulfill()
            default:
                XCTFail("Request did not return value")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRemoveStub() {
        let expectation = self.expectation(description: "Fetch model")
        
        let resource = Resource<ModelA>(method: .get, path: "/test")
        
        let stub = StubResponse(statusCode: 200, encodable: ModelA(a: "a"), delay: 0.1)
        APIClient.shared.stubProvider.register(stub: stub, for: resource)
        APIClient.shared.stubProvider.remove(stub: stub)
        
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
        
}

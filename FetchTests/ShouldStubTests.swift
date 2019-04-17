//
//  ShouldStubTests.swift
//  FetchTests
//
//  Created by Michael Heinzl on 15.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import XCTest
import Alamofire
@testable import Fetch

class ShouldStubTests: XCTestCase {

    override func setUp() {
        APIClient.shared.setup(with: Config(
            baseURL: URL(string: "https://www.asdf.at")!
        ))
    }

    func testShouldStubInResourceStubs() {
        let expectation = self.expectation(description: "Fetch model")
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test",
            shouldStub: true,
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "a"), delay: 0))
        
        resource.request { (result) in
            switch result {
            case let .success(value):
                XCTAssertEqual(value.model.a, "a")
                expectation.fulfill()
            default:
                XCTFail("Request did not return value")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testShouldStubSetGlobalStubs() {
        let customApiClient = APIClient(config: Config(
            baseURL: URL(string: "https://www.asdf.at")!,
            shouldStub: true
        ))
        let expectation = self.expectation(description: "Fetch model")
        let resource = Resource<ModelA>(
            apiClient: customApiClient,
            method: .get,
            path: "/test",
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "a"), delay: 0))
        
        resource.request { (result) in
            switch result {
            case let .success(value):
                XCTAssertEqual(value.model.a, "a")
                expectation.fulfill()
            default:
                XCTFail("Request did not return value")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testShouldStubInResourceOverwritesGlobalStubs() {
        let customApiClient = APIClient(config: Config(
            baseURL: URL(string: "https://www.asdf.at")!,
            shouldStub: false
        ))
        let expectation = self.expectation(description: "Fetch model")
        let resource = Resource<ModelA>(
            apiClient: customApiClient,
            method: .get,
            path: "/test",
            shouldStub: true,
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "a"), delay: 0))
        
        resource.request { (result) in
            switch result {
            case let .success(value):
                XCTAssertEqual(value.model.a, "a")
                expectation.fulfill()
            default:
                XCTFail("Request did not return value")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testShouldStubInResourceWithoutStubDoesNotStub() {
        let expectation = self.expectation(description: "Fetch model")
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test",
            shouldStub: true)
        
        resource.request { (result) in
            switch result {
            case .success:
                XCTFail("Request did return value")
            default:
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

}

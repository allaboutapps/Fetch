//
//  NestingTests.swift
//  FetchTests
//
//  Created by Michael Heinzl on 11.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import XCTest
import Alamofire
import Fetch

class NestingTests: XCTestCase {

    override func setUp() {
        APIClient.shared.setup(with: Config(
            baseURL: URL(string: "https://www.asdf.at")!,
            shouldStub: true
        ))
    }

    func testNestedDecodingSuccess() {
        let model = ModelA(a: "asdf")
        let nesting: Encodable = ["deep": [5: ["result": model]]]
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test",
            rootKeys: ["deep", "5", "result"],
            stub: StubResponse(statusCode: 200, encodable: nesting, delay: 0.1))
        let expectation = self.expectation(description: "Fetch value")
        
        resource.request { (result) in
            switch result {
            case .success(let response):
                XCTAssertEqual(model, response.model)
                expectation.fulfill()
            case .failure:
                XCTFail("Request did return error")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testNestedDecodingTooManyKeys() {
        let model = ModelA(a: "asdf")
        let nesting: Encodable = ["deep": [5: ["result": model]]]
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test",
            rootKeys: ["deep", "5", "result", "asdf"],
            stub: StubResponse(statusCode: 200, encodable: nesting, delay: 0.1))
        let expectation = self.expectation(description: "Fetch error")
        
        resource.request { (result) in
            switch result {
            case .failure(.decoding(.keyNotFound)):
                expectation.fulfill()
            default:
                XCTFail("Request did not return error")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testNestedDecodingTooFewKeys() {
        let model = ModelA(a: "asdf")
        let nesting: Encodable = ["deep": [5: ["result": model]]]
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test",
            rootKeys: ["deep", "5"],
            stub: StubResponse(statusCode: 200, encodable: nesting, delay: 0.1))
        let expectation = self.expectation(description: "Fetch error")
        
        resource.request { (result) in
            switch result {
            case .failure(.decoding(.keyNotFound)):
                expectation.fulfill()
            default:
                XCTFail("Request did not return error")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testEmptyRootKeysShouldFail() {
        let model = ModelA(a: "asdf")
        let nesting: Encodable = ["deep": [5: ["result": model]]]
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test",
            rootKeys: [],
            stub: StubResponse(statusCode: 200, encodable: nesting, delay: 0.1))
        let expectation = self.expectation(description: "Fetch error")
        
        resource.request { (result) in
            switch result {
            case .failure(.decoding(.dataCorrupted)):
                expectation.fulfill()
            default:
                XCTFail("Request did not return error")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

}

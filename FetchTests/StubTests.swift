//
//  StubTests.swift
//  FetchTests
//
//  Created by Michael Heinzl on 11.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import XCTest
import Alamofire
import Fetch

class StubTests: XCTestCase {

    override func setUp() {
        APIClient.shared.setup(with: Config(
            baseURL: URL(string: "https://www.asdf.at")!,
            shouldStub: true
        ))
    }

    func testSuccessfulStubbingOfDecodable() {
        let expectation = self.expectation(description: "Fetch model")
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test",
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "a"), delay: 0.1))
        
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
    
    func testStubbedStatusCode() {
        let expectation = self.expectation(description: "Fetch model")
        let statusCode = 205
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test",
            stub: StubResponse(statusCode: statusCode, encodable: ModelA(a: "a"), delay: 0.1))
        
        resource.request { (result) in
            switch result {
            case let .success(response):
                XCTAssertEqual(response.urlResponse.statusCode, statusCode)
                expectation.fulfill()
            default:
                XCTFail("Request did not return value")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testStubbedModelFromFile() {
        let expectation = self.expectation(description: "Fetch model")
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test",
            stub: StubResponse(statusCode: 200, fileName: "modela.json", delay: 0.1, bundle: Bundle(for: type(of: self))))
        resource.request { (result) in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.model.a, "a")
                expectation.fulfill()
            case .failure:
                XCTFail("Request did not return value")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testStubbedHTTPHeaders() {
        let expectation = self.expectation(description: "Fetch model")
        let headers = HTTPHeaders([
            "httpHeaderKey1": "httpHeaderValue1",
            "httpHeaderKey2": "httpHeaderValue2"
            ])
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test",
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "a"), headers: headers, delay: 0.1))
        
        resource.request { (result) in
            switch result {
            case let .success(response):
                XCTAssertEqual(response.urlResponse.headers.dictionary, headers.dictionary)
                expectation.fulfill()
            default:
                XCTFail("Request did not return value")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testMultipleStubsReturnCorrectResult() {
        let requestCount = 5
        for i in 1...requestCount {
            let model = ModelA(a: String(i))
            let stub = StubResponse(statusCode: 200, encodable: model, delay: 0.1)
            let resource = Resource<ModelA>(path: "/test", stub: stub)
            let expectation = self.expectation(description: "Fetch model id: \(i)")
            
            resource.request { (result) in
                switch result {
                case let .success(value):
                    XCTAssertEqual(value.model.a, String(i), "Model does not contain correct value")
                    expectation.fulfill()
                default:
                    XCTFail("Request did not return value")
                }
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testErrorStub() {
        let inputError = NSError(domain: "TestDomain", code: 999, userInfo: nil)
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test",
            stub: StubError(error: inputError, delay: 0.1))
        let expectation = self.expectation(description: "Fetch error")
        
        resource.request { (result) in
            switch result {
            case .success:
                XCTFail("Request did not return error")
            case .failure(let error):
                if case .network(let afError, _) = error {
                    guard let nsError = afError.underlyingError as NSError? else {
                        XCTFail("Expect error is not set")
                        return
                    }
                    
                    XCTAssertEqual(nsError.domain, inputError.domain, "Same error domain as input")
                    XCTAssertEqual(nsError.code, inputError.code, "Same error code as input")
                } else {
                    XCTFail("Expect error is not set")
                }
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
}

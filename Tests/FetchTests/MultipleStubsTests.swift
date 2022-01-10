//
//  MultipleStubsTests.swift
//  FetchTests
//
//  Created by Michael Heinzl on 11.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import XCTest
import Alamofire
import Fetch

class MultipleStubsTests: XCTestCase {

    override func setUp() {
        APIClient.shared.setup(with: Config(
            baseURL: URL(string: "https://www.asdf.at")!,
            shouldStub: true
        ))
    }
    func testAlternatingStub() {
        struct Foo: Codable {
            let a: Int
        }
        let stubs: [Stub] = [
            StubResponse(statusCode: 200, encodable: Foo(a: 0), delay: 0.1),
            StubResponse(statusCode: 200, encodable: Foo(a: 1), delay: 0.2),
            StubError(error: NSError(domain: "TestDomain", code: 999, userInfo: nil), delay: 0.1),
            StubResponse(statusCode: 200, encodable: Foo(a: 3), delay: 0.1)
        ]
        let stub = AlternatingStub(stubs: stubs)
        let resource = Resource<Foo>(
            method: .get,
            path: "/test")
        
        APIClient.shared.stubProvider.register(stub: stub, for: resource)
        
        for i in 0...9 {
            let expectation = self.expectation(description: "Fetch result")
            
            resource.request { (result) in
                let index = i % stubs.count
                switch result {
                case .success(let value):
                    XCTAssertEqual(value.model.a, index, "Should return correct foo value")
                case .failure:
                    XCTAssert(stubs[index] is StubError, "Should be an error")
                }
                expectation.fulfill()
            }
            waitForExpectations(timeout: 5, handler: nil)
        }
    }
    
    func testRandomStub() {
        struct Foo: Codable {
            let a: Int
        }
        let stubs: [Stub] = [
            StubResponse(statusCode: 200, encodable: Foo(a: 0), delay: 0.1),
            StubResponse(statusCode: 200, encodable: Foo(a: 1), delay: 0.2),
            StubError(error: NSError(domain: "TestDomain", code: 999, userInfo: nil), delay: 0.1),
            StubResponse(statusCode: 200, encodable: Foo(a: 3), delay: 0.1)
        ]
        let stub = RandomStub(stubs: stubs)
        let resource = Resource<Foo>(
            method: .get,
            path: "/test")
        
        APIClient.shared.stubProvider.register(stub: stub, for: resource)
        
        for _ in 0...9 {
            let expectation = self.expectation(description: "Fetch result")
            let index = stub.index
            resource.request { (result) in
                switch result {
                case .success(let value):
                    XCTAssertEqual(value.model.a, index, "Should return correct foo value")
                case .failure:
                    XCTAssert(stubs[index] is StubError, "Should be an error")
                }
                expectation.fulfill()
            }
            waitForExpectations(timeout: 5, handler: nil)
        }
    }

}

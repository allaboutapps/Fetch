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

    func testSuccessfulStubbingOfDecodable() {
        let expectation = self.expectation(description: "Fetch model")
        
        let resource = Resource<ModelA>(method: .get, path: "/test")
        
        let stub = StubResponse(statusCode: 200, encodable: ModelA(a: "a"), delay: 0.1)
        
        APIClient.shared.config.stubProvider.register(stub: stub, for: resource.stubKey)
        
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
        
}

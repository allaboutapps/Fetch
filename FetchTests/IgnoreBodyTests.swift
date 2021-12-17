//
//  IgnoreBodyTests.swift
//  FetchTests
//
//  Created by Michael Heinzl on 17.05.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import XCTest
import Alamofire
@testable import Fetch

class IgnoreBodyTests: XCTestCase {
    
    override func setUp() {
        APIClient.shared.setup(with: Config(
            baseURL: URL(string: "https://www.asdf.at")!,
            shouldStub: true
        ))
    }
    
    func testIgnoreBodyDoesNotDecode() {
        let expectation = self.expectation(description: "Fetch model")
        let resource = Resource<IgnoreBody>(
            method: .get,
            path: "/test")
        
        APIClient.shared.stubProvider.register(stub: StubResponse(statusCode: 200, encodable: ModelA(a: "a"), delay: 0.0), for: resource)
        
        resource.request { (result) in
            switch result {
            case .success:
                expectation.fulfill()
            default:
                XCTFail("Request did not return value")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

}

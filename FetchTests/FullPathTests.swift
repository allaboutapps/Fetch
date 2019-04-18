//
//  FullPathTests.swift
//  FetchTests
//
//  Created by Michael Heinzl on 18.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import XCTest
import Fetch

class FullPathTests: XCTestCase {

    override func setUp() {
        APIClient.shared.setup(with: Config(
            baseURL: URL(string: "https://www.asdf.at")!,
            shouldStub: true
        ))
    }
    
    func testAbsoluteHTTPPathDoesNotUseBaseURL() {
        let path = "http://www.fullpath.at/rest"
        let resource = Resource<ModelA>(path: path)
        XCTAssertEqual(path, resource.url.absoluteString, "Path should be equal to url string")
    }
    
    func testAbsoluteHTTPSPathDoesNotUseBaseURL() {
        let path = "https://www.fullpath.at/rest"
        let resource = Resource<ModelA>(path: path)
        XCTAssertEqual(path, resource.url.absoluteString, "Path should be equal to url string")
    }
    
    func testRelativePathDoesUseBaseURL() {
        let path = "rest/test"
        let resource = Resource<ModelA>(path: path)
        XCTAssertNotEqual(path, resource.url.absoluteString, "Path should not be equal to url string")
    }

}

//
//  DispatchQueueTests.swift
//  FetchTests
//
//  Created by Michael Heinzl on 15.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import XCTest
import Alamofire
import Fetch

class DispatchQueueTests: XCTestCase {

    override func setUp() {
        APIClient.shared.setup(with: Config(
            baseURL: URL(string: "https://www.asdf.at")!,
            shouldStub: true
        ))
    }

    func testResponseFailureOnCorrectQueue() {
        let expectation = self.expectation(description: "Fetch model")
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test",
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "a"), delay: 0.1))
        let testQueue = DispatchQueue(label: "test-queue")
        let testQueueKey = DispatchSpecificKey<Void>()
        testQueue.setSpecific(key: testQueueKey, value: ())
        resource.request(queue: testQueue) { (result) in
            switch result {
            case .success:
                XCTAssertNotNil(DispatchQueue.getSpecific(key: testQueueKey), "callback should be called on specified queue")
                expectation.fulfill()
            default:
                XCTFail("Request did not return value")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testResponseSuccessOnCorrectQueue() {
        let expectation = self.expectation(description: "Fetch model")
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test",
            stub: StubResponse(statusCode: 500, encodable: ModelA(a: "a"), delay: 0.1))
        let testQueue = DispatchQueue(label: "test-queue")
        let testQueueKey = DispatchSpecificKey<Void>()
        testQueue.setSpecific(key: testQueueKey, value: ())
        resource.request(queue: testQueue) { (result) in
            switch result {
            case .failure:
                XCTAssertNotNil(DispatchQueue.getSpecific(key: testQueueKey), "callback should be called on specified queue")
                expectation.fulfill()
            default:
                XCTFail("Request did return value")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
}

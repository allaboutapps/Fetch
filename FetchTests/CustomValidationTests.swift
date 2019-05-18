//
//  CustomValidationTests.swift
//  FetchTests
//
//  Created by Michael Heinzl on 18.05.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import XCTest
import Alamofire
import Fetch

class CustomValidationTests: XCTestCase {
    
    override func setUp() {
        APIClient.shared.setup(with: Config(
            baseURL: URL(string: "https://www.asdf.at")!,
            shouldStub: true
        ))
    }
    
    private enum ValidationError: Error {
        case wrongStatusCode
    }
    
    func testSuccessfulStubbingOfDecodable() {
        let testValidation: DataRequest.Validation = { (_, response, _) -> DataRequest.ValidationResult in
            if response.statusCode == 222 {
                return .failure(ValidationError.wrongStatusCode)
            } else {
                return .success(())
            }
        }
        let expectation = self.expectation(description: "Fetch model")
        let resource = Resource<ModelA>(
            method: .get,
            path: "/test",
            customValidation: testValidation,
            stub: StubResponse(statusCode: 222, encodable: ModelA(a: "a"), delay: 0.1))
        
        resource.request { (result) in
            switch result {
            case .failure(.other(error: let otherError)):
                XCTAssertEqual((otherError as? ValidationError), .wrongStatusCode)
                expectation.fulfill()
            default:
                XCTFail("Request did not return error")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
}

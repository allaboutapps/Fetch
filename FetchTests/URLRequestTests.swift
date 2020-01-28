//
//  URLRequestTests.swift
//  FetchTests
//
//  Created by Michael Heinzl on 11.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import XCTest
import Alamofire
@testable import Fetch

class URLRequestTests: XCTestCase {

    override func setUp() {
        APIClient.shared.setup(with: Config(
            baseURL: URL(string: "https://www.asdf.at")!,
            defaultHeaders: HTTPHeaders(["DefaultHeader": "default", "OtherHeader": "other"]),
            shouldStub: true
        ))
    }

    func testHttpDefaultContentTypeIsSetInHeader() {
        let resource = Resource<ModelA>(
            method: .post,
            path: "/test",
            body: .encodable(ModelA(a: "a")))
        let urlRequest = try! resource.asURLRequest()
        let contains = urlRequest.allHTTPHeaderFields?.contains(where: { (arg) -> Bool in
            let (key, value) = arg
            return key == "Content-Type" && value == "application/json"
        }) ?? false
        XCTAssertTrue(contains)
    }
    
    func testCustomHeaderOverrideDefaultHeaderButKeepOther() {
        let resource = Resource<ModelA>(
            headers: HTTPHeaders(["DefaultHeader": "custom"]),
            path: "/test")
        let urlRequest = try! resource.asURLRequest()
        let containsCustomHeader = urlRequest.allHTTPHeaderFields?.contains(where: { (arg) -> Bool in
            let (key, value) = arg
            return key == "DefaultHeader" && value == "custom"
        }) ?? false
        XCTAssertTrue(containsCustomHeader)
        let containsOtherHeader = urlRequest.allHTTPHeaderFields?.contains(where: { (arg) -> Bool in
            let (key, value) = arg
            return key == "OtherHeader" && value == "other"
        }) ?? false
        XCTAssertTrue(containsOtherHeader)
    }
    
    func testCustomEncoding() {
        let inputModel = ModelA(a: "asdfasd")
        let resource = Resource<ModelA>(
            path: "/test",
            body: .encodable(inputModel),
            encode: { (encodable: Encodable) throws -> (Data, HTTPContentType?) in
                let data = try PropertyListEncoder().encode(AnyEncodable(encodable))
                return (data, HTTPContentType.custom(value: "property-list"))
        })
        let urlRequest = try! resource.asURLRequest()
        let body = (urlRequest.httpBody ?? Data())
        let outputModel = try! PropertyListDecoder().decode(ModelA.self, from: body)
        XCTAssertEqual(inputModel, outputModel)
        let contains = urlRequest.allHTTPHeaderFields?.contains(where: { (arg) -> Bool in
            let (key, value) = arg
            return key == "Content-Type" && value == "property-list"
        }) ?? false
        XCTAssertTrue(contains)
    }
    
    func testCustomDeconding() {
        struct Foo: Codable {
            let seconds: TimeInterval
        }
        let date = Date()
        let seconds = date.timeIntervalSince1970
        let resource = Resource<Foo>(
            path: "/test",
            stub: StubResponse(statusCode: 200, encodable: Foo(seconds: seconds), delay: 0.1),
            decode: { (data: Data) throws -> Foo in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                return try decoder.decode(Foo.self, from: data)
        })
        let expectation = self.expectation(description: "Fetch seconds")
        resource.request { (result) in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.model.seconds, seconds)
                expectation.fulfill()
            default:
                XCTFail("Wrong response")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUrlParameter() {
        let resource = Resource<Empty>(
            path: "/test",
            urlParameters: ["url": "parameter"])
        let urlRequest = try! resource.asURLRequest()
        XCTAssertTrue(urlRequest.url?.absoluteString.hasSuffix("?url=parameter") ?? false)
    }
    
    func testFetchResponse() {
        let fetchAExpectation = expectation(description: "FetchA")
        
        let resourceA = Resource<ModelA>(
            path: "/test",
            cachePolicy: .networkOnlyUpdateCache,
            stub: StubResponse(statusCode: 200, encodable: ModelA(a: "366"), delay: 0.1)
        )
        
        resourceA.fetch { (result, _) in
            switch result {
            case .success(let value):
                XCTAssertNotNil(value)
                fetchAExpectation.fulfill()
            default:
                break
            }
        }
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}

//
//  MockURLProtocol.swift
//  Fetch
//
//  Created by Michael Heinzl on 05.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

class StubbedURLProtocol: URLProtocol {
    
    private static var registeredStubs = [String: Stub]()
    
    static func registerStub(_ stub: Stub, for id: String) {
        registeredStubs[id] = stub
    }
    
    private let queue = DispatchQueue(label: "at.allaboutapps.fetch.stubQueue")
    
    override func startLoading() {
        // Get the corresponding stub from the registry using the stubId set the header
        // The stubId is set in the resource if necessary
        guard
            let requestId = request.headers[StubbedURLProtocol.stubIdHeader],
            let stub = StubbedURLProtocol.registeredStubs[requestId]
        else {
            preconditionFailure("Stubbed request was not set correctly")
        }
        
        if stub.delay <= 0.0 {
            handleStub(stub)
        } else {
            queue.asyncAfter(deadline: .now() + stub.delay) { [weak self] in
                self?.handleStub(stub)
            }
        }
    }
    
    private func handleStub(_ stub: Stub) {
        guard let client = client else { return }
        
        switch stub.result {
        case .success(let (statusCode, data)):
            let urlResponse = HTTPURLResponse(
                url: URL(string: "https://mocked.com")!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: [:])!
            
            client.urlProtocol(self, didReceive: urlResponse, cacheStoragePolicy: .notAllowed)
            client.urlProtocol(self, didLoad: data)
            client.urlProtocolDidFinishLoading(self)
            
        case .failure(let error):
            client.urlProtocol(self, didFailWithError: error)
        }
    }
    
    static let stubIdHeader = "StubbedURLProtocol.stubId"
    
    // MARK: - Helper
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        return false
    }
    
    override func stopLoading() {}
}

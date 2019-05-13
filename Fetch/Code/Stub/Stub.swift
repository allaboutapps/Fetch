//
//  Stub.swift
//  Fetch
//
//  Created by Michael Heinzl on 10.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Alamofire

/// A `Stub` represents a network response, which can be used to imitate an API endpoint
public protocol Stub {
    
    /// HTTP status code
    typealias StatusCode = Int
    
    /// The result of the stubbed network call
    /// It can be used to return a HTTP status code with a HTTP body and HTTP headers or an error
    var result: Result<(StatusCode, Data, HTTPHeaders), Error> { get }
    
    /// The id to identify a `Stub`. It is used to match the stub to the response
    var id: UUID { get }
    
    /// The `TimeInterval` after which the stub is returned to simulate a network delay
    var delay: TimeInterval { get }
}

/// A simple `Stub` representing a successful response
public struct StubResponse: Stub {
    public let id = UUID()
    public let result: Result<(StatusCode, Data, HTTPHeaders), Error>
    public let delay: TimeInterval
    
    /// Initializes a new `StubResponse` using a data object
    ///
    /// - Parameters:
    ///   - statusCode: HTTP status code
    ///   - data: HTTP body data
    ///   - delay: Simulated network delay
    public init(statusCode: StatusCode, data: Data, headers: HTTPHeaders = HTTPHeaders(), delay: TimeInterval) {
        self.result = .success((statusCode, data, headers))
        self.delay = delay
    }
    
    /// Initializes a new `StubResponse` using a file
    ///
    /// - Parameters:
    ///   - statusCode: HTTP status code
    ///   - fileName: The name of the file (e.g. test.json). The content of the file is used as HTTP body
    ///   - delay: Simulated network delay
    ///   - bundle: The `Bundle` containing the file, default Bundle.main
    public init(statusCode: StatusCode, fileName: String, headers: HTTPHeaders = HTTPHeaders(), delay: TimeInterval, bundle: Bundle = Bundle.main) {
        let split = fileName.split(separator: ".")
        let name = String(split[0])
        let fileExtension = String(split[1])
        let path = bundle.path(forResource: name, ofType: fileExtension)!
        
        self.init(statusCode: statusCode, data: try! Data(contentsOf: URL(fileURLWithPath: path)), headers: headers, delay: delay)
    }
    
    /// Initializes a new `StubResponse` using a `Encodable` and a `JSONEncoder`
    ///
    /// - Parameters:
    ///   - statusCode: HTTP status code
    ///   - encodable: The object which will be encoded
    ///   - encoder: The `JSONEncoder` used to encode the `Encodable`
    ///   - delay: Simulated network delay
    public init(statusCode: StatusCode, encodable: Encodable, encoder: ResourceEncoderProtocol = APIClient.shared.config.encoder, headers: HTTPHeaders = HTTPHeaders(), delay: TimeInterval) {
        self.init(statusCode: statusCode, data: try! encoder.encode(AnyEncodable(encodable)), headers: headers, delay: delay)
    }
    
}

/// A simple `Stub` representing a unsuccessful response
public struct StubError: Stub {
    public let id = UUID()
    public let result: Result<(StatusCode, Data, HTTPHeaders), Error>
    public let delay: TimeInterval
    
    /// Initializes a new `StubError`
    ///
    /// - Parameters:
    ///   - error: The resulting error
    ///   - delay: Simulated network delay
    public init(error: Error, delay: TimeInterval) {
        self.result = .failure(error)
        self.delay = delay
    }
}

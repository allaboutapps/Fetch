//
//  APIClient.swift
//  Fetch
//
//  Created by Michael Heinzl on 02.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Alamofire

extension DispatchQueue {
    static let asyncCompletionQueue = DispatchQueue(label: "at.allaboutapps.fetch.asyncCompletionQueue", attributes: .concurrent)
    static let decodingQueue = DispatchQueue(label: "at.allaboutapps.fetch.decodingQueue")
}

/// A configuration object used to setup an `APIClient`
public struct Config {
    
    public var baseURL: URL
    public var defaultHeaders: HTTPHeaders
    public var timeout: TimeInterval
    public var urlSession: URLSessionConfiguration
    public var eventMonitors: [EventMonitor]
    public var interceptor: RequestInterceptor?
    public var decoder: ResourceDecoderProtocol
    public var encoder: ResourceEncoderProtocol
    public var cache: Cache?
    public var cachePolicy: CachePolicy
    public var protocolClasses: [AnyClass]
    public var shouldStub: Bool?
    
    /// Initializes a new `Config`
    ///
    /// - Parameters:
    ///   - baseURL: The base `URL` used for all request, if not specified by the `Resource`
    ///   - defaultHeaders: The `HTTPHeaders` used for all request, if not specified by the `Resource`
    ///   - timeout: The request timeout interval controls how long (in seconds) a task should wait for additional data to arrive before giving up
    ///   - urlSession: The `URLSessionConfiguration` passed to the Alamofire `Session`
    ///   - eventMonitors: The `EventMonitor` array passed to the Alamofire `Session`
    ///   - adapter: The `RequestAdapter` passed to the Alamofire `Session`
    ///   - retrier: The `RequestRetrier` passed to the Alamofire `Session`
    ///   - jsonDecoder: The `JSONDecoder` used for all `Resources`, if not specified by the `Resource`
    ///   - jsonEncoder: The `JSONEncoder` used for all `Resources`, if not specified by the `Resource`
    ///   - cache: The `Cache` used for all `Resources`
    ///   - cachePolicy: The `CachePolicy` used for all `Resources`
    ///   - protocolClasses: Custom protocolClasses for URLSessionConfiguration
    ///   - shouldStub: Indicates if requests should be stubbed, can be overwritten by the resource
    public init(baseURL: URL,
                defaultHeaders: HTTPHeaders = HTTPHeaders.default,
                timeout: TimeInterval = 60 * 2,
                urlSession: URLSessionConfiguration = URLSessionConfiguration.default,
                eventMonitors: [EventMonitor] = [APILogger(verbose: true)],
                interceptor: RequestInterceptor? = nil,
                jsonDecoder: ResourceDecoderProtocol = JSONDecoder(),
                jsonEncoder: ResourceEncoderProtocol = JSONEncoder(),
                cache: Cache? = nil,
                cachePolicy: CachePolicy = .networkOnlyUpdateCache,
                protocolClasses: [AnyClass] = [],
                shouldStub: Bool? = nil) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.timeout = timeout
        self.urlSession = urlSession
        self.eventMonitors = eventMonitors
        self.interceptor = interceptor
        self.decoder = jsonDecoder
        self.encoder = jsonEncoder
        self.cache = cache
        self.cachePolicy = cachePolicy
        self.protocolClasses = protocolClasses
        self.shouldStub = shouldStub
    }
}

/// The `NetworkResponse` represents an parsed response from the network.
public struct NetworkResponse<T> {
    
    /// The parsed model decoded from the response body
    public let model: T
    
    /// The associated `HTTPURLResponse`
    public let urlResponse: HTTPURLResponse

    internal init(model: T, urlResponse: HTTPURLResponse) {
        self.model = model
        self.urlResponse = urlResponse
    }
}

/// The `APIClient` is the interface to the network and it is used by a `Resource` to send http requests.
public class APIClient {

    typealias CompletionCallback<T> = ((Swift.Result<NetworkResponse<T>, FetchError>) -> Void)
    
    /// Initializes a new `APIClient`
    ///
    /// - Parameter config: The config which is used for the setup
    public init(config: Config) {
        setup(with: config)
    }
    
    private init() {}
    
    /// The default `APIClient`
    public static let shared = APIClient()
    
    private var _config: Config?
    
    /// The `Config` passed from the `setup` function
    public var config: Config {
        assert(_config != nil, "Setup of APIClient was not called!")
        return _config!
    }
    
    public var session: Session!

    /// Configures an `APIClient` with the given `config`
    ///
    /// - Parameter config: used to setup the `APIClient`
    ///
    /// - Important: setup has to be called once before using the `APIClient`
    public func setup(with config: Config) {
        self._config = config
        
        let configuration = config.urlSession
        configuration.protocolClasses = config.protocolClasses + [StubbedURL.self]
        configuration.timeoutIntervalForRequest = config.timeout
        
        session = Session(
            configuration: configuration,
            interceptor: config.interceptor,
            eventMonitors: config.eventMonitors)
    }
    
    public func registerURLProtocolClass(_ someClass: AnyClass) {
        URLProtocol.registerClass(someClass)
    }
    
    public func unregisterClassURLProtocolClass(_ someClass: AnyClass) {
        URLProtocol.unregisterClass(someClass)
    }
    
    // MARK: - Resource
    
    @discardableResult internal func request<T>(_ resource: Resource<T>, queue: DispatchQueue, completion: @escaping CompletionCallback<T>) -> RequestToken {
        precondition(_config != nil, "Setup of APIClient was not called!")
        
        register(resource)
        
        let urlRequest: URLRequest
        do {
            urlRequest = try resource.asURLRequest()
        } catch {
            queue.async {
                completion(.failure(.other(error: error)))
            }
            return RequestToken({})
        }
        
        var dataRequest: DataRequest
        if let multipartFormData = resource.multipartFormData {
            dataRequest = session.upload(multipartFormData: multipartFormData, with: urlRequest)
        } else {
            dataRequest = session.request(urlRequest)
        }
        
        if let customValidation = resource.customValidation {
            dataRequest = dataRequest.validate(customValidation)
        }
        
        dataRequest
            .validate() // Validate response (status codes + content types)
            .responseData(queue: DispatchQueue.decodingQueue, completionHandler: { (dataResponse) in
                // Map and decode Data to Object
                let decodedResponse = dataResponse.tryMap { (data) throws -> T in
                    if T.self == IgnoreBody.self {
                        return IgnoreBody() as! T
                    } else {
                        return try resource.decode(data)
                    }
                }
                
                switch decodedResponse.result {
                case .success(let model):
                    if let urlResponse = dataResponse.response {
                        queue.async {
                            completion(.success(NetworkResponse(model: model, urlResponse: urlResponse)))
                        }
                    } else {
                        queue.async {
                            completion(.failure(.invalidResponse))
                        }
                    }
                case .failure(let error):
                    let fetchError: FetchError
                    switch error {
                    case let afError as AFError:
                        if afError.isExplicitlyCancelledError {
                            return
                        } else {
                            fetchError = .network(error: afError, responseData: decodedResponse.data)
                        }
                    case let decodingError as DecodingError:
                        // TODO: log decoding error
                        fetchError = .decoding(error: decodingError)
                    default:
                         // TODO: log other error
                        fetchError = .other(error: error)
                    }
                    queue.async {
                        completion(.failure(fetchError))
                    }
                }
            })
        
        return RequestToken {
            dataRequest.cancel()
        }
    }
    
    private func register<T>(_ resource: Resource<T>) {
        guard let stub = resource.stubIfNeeded else { return }
        
        StubbedURL.registerStub(stub, for: stub.id.uuidString)
    }
}

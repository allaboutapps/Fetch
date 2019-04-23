//
//  APIClient.swift
//  Fetch
//
//  Created by Michael Heinzl on 02.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Alamofire

/// A configuration object used to setup an `APIClient`
public struct Config {
    public var baseURL: URL
    public var defaultHeaders: HTTPHeaders
    public var timeout: TimeInterval
    public var eventMonitors: [EventMonitor]
    public var interceptor: RequestInterceptor?
    public var decoder: ResourceDecoderProtocol
    public var encoder: ResourceEncoderProtocol
    public var cache: Cache?
    public var cachePolicy: CachePolicy
    public var shouldStub: Bool?
    
    /// Initializes a new `Config`
    ///
    /// - Parameters:
    ///   - baseURL: The base `URL` used for all request, if not specified by the `Resource`
    ///   - defaultHeaders: The `HTTPHeaders` used for all request, if not specified by the `Resource`
    ///   - timeout: The request timeout interval controls how long (in seconds) a task should wait for additional data to arrive before giving up
    ///   - eventMonitors: The `EventMonitor` array passed to the Alamofire `Session`
    ///   - adapter: The `RequestAdapter` passed to the Alamofire `Session`
    ///   - retrier: The `RequestRetrier` passed to the Alamofire `Session`
    ///   - jsonDecoder: The `JSONDecoder` used for all `Resources`, if not specified by the `Resource`
    ///   - jsonEncoder: The `JSONEncoder` used for all `Resources`, if not specified by the `Resource`
    ///   - cache: The `Cache` used for all `Resources`
    ///   - cachePolicy: The `CachePolicy` used for all `Resources`
    ///   - shouldStub: Indicates if requests should be stubbed, can be overwritten by the resource
    public init(baseURL: URL,
                defaultHeaders: HTTPHeaders = HTTPHeaders.default,
                timeout: TimeInterval = 60 * 2,
                eventMonitors: [EventMonitor] = [APILogger(verbose: true)],
                interceptor: RequestInterceptor? = nil,
                jsonDecoder: ResourceDecoderProtocol = JSONDecoder(),
                jsonEncoder: ResourceEncoderProtocol = JSONEncoder(),
                cache: Cache? = nil,
                cachePolicy: CachePolicy = .networkOnlyUpdateCache,
                shouldStub: Bool? = nil) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.timeout = timeout
        self.eventMonitors = eventMonitors
        self.interceptor = interceptor
        self.decoder = jsonDecoder
        self.encoder = jsonEncoder
        self.cache = cache
        self.cachePolicy = cachePolicy
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
    
    private var session: Session!
    
    let decodingQueue = DispatchQueue(label: "at.allaboutapps.fetch.decodingQueue")
    
    /// Configures an `APIClient` with the given `config`
    ///
    /// - Parameter config: used to setup the `APIClient`
    ///
    /// - Important: setup has to be called once before using the `APIClient`
    public func setup(with config: Config) {
        self._config = config
        
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [StubbedURL.self]
        configuration.timeoutIntervalForRequest = config.timeout
        
        session = Session(
            configuration: configuration,
            interceptor: config.interceptor,
            eventMonitors: config.eventMonitors)
        
    }
    
    // MARK: - Resource
    
    @discardableResult internal func request<T>(_ resource: Resource<T>, queue: DispatchQueue, completion: @escaping (Swift.Result<NetworkResponse<T>, FetchError>) -> Void) -> RequestToken {
        precondition(_config != nil, "Setup of APIClient was not called!")
        
        let session = prepareSession(for: resource)
        
        let urlRequest: URLRequest
        do {
            urlRequest = try resource.asURLRequest()
        } catch {
            queue.async {
                completion(.failure(.other(error: error)))
            }
            return RequestToken({})
        }
        
        let dataRequest: DataRequest
        if let multipartFormData = resource.multipartFormData {
            dataRequest = session.upload(multipartFormData: multipartFormData, with: urlRequest)
        } else {
            dataRequest = session.request(urlRequest)
        }
        
        dataRequest
            .validate() // Validate response (status codes + content types)
            .responseData(queue: self.decodingQueue, completionHandler: { (dataResponse) in
                // Map and decode Data to Object
                let decodedResponse = dataResponse.flatMap { try resource.decode($0) }
                
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
                        fetchError = .decoding(error: decodingError)
                    default:
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
    
    private func prepareSession<T>(for resource: Resource<T>) -> Session {
        guard let stub = resource.stubIfNeeded else { return session }
        
        StubbedURL.registerStub(stub, for: stub.id.uuidString)
        return session
    }
}

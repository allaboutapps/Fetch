//
//  Resource.swift
//  Fetch
//
//  Created by Michael Heinzl on 02.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Alamofire

/// A `Resource` represents all data necessary for a network request combined with the decoding of the response.
/// Additionally, caching behaviour can be specified

public class Resource<T: Decodable>: CacheableResource {
    
    public typealias DecodingClosure = (Data) throws -> T
    public typealias EncodingClosure = (Encodable) throws -> (Data, HTTPContentType?)
    
    public let apiClient: APIClient
    public let headers: HTTPHeaders?
    public let method: HTTPMethod
    public let baseURL: URL?
    public let path: String
    public let urlParameters: Parameters?
    public let body: Encodable?
    public let rootKeys: [String]?
    public let multipartFormData: MultipartFormData?
    public let cachePolicy: CachePolicy?
    public let cacheGroup: String?
    public let cacheExpiration: Expiration?
    public let customCacheKey: String?
    public let shouldStub: Bool?
    public let stub: Stub?
    public let decode: DecodingClosure
    public let encode: EncodingClosure

    /// The final `URL` used in a network request, using the base URL from the resource or from the `APIClient` and the path
    public var url: URL {
        return (baseURL ?? apiClient.config.baseURL).appendingPathComponent(path)
    }
    
    /// A helper to access the cache specified in the `APIClient`
    public var cache: Cache? {
        return apiClient.config.cache
    }
    
    /// The key used to access the cache, if none is provided the key is computed
    public lazy var cacheKey: String = {
        return customCacheKey ?? computeCacheKey()
    }()
    
    /// Returns a `Stub` if shouldStub is set in the `Resource` or the `APIClient`, if a `Stub` is available
    public var stubIfNeeded: Stub? {
        if let stub = self.stub, shouldStub ?? apiClient.config.shouldStub ?? false {
            return stub
        } else {
            return nil
        }
    }

    /// Initializes a new `Resource`
    ///
    /// - Parameters:
    ///   - apiClient: The `APIClient` used for the request
    ///   - headers: The `HTTPHeaders`used for the request, overrides duplicated keys from the `APIClient`
    ///   - method: The HTTP method used for the request
    ///   - baseURL: The base URL used for the request, if nil uses the base URL from the `APIClient`
    ///   - path: The url path additionally to the `baseURL`
    ///   - urlParameters: The url paramters used for the query string of the request (URLEncoding(destination: .queryString))
    ///   - body: The object which will be encoded in the HTTP body
    ///   - rootKeys: The `rootKeys` are used to decode multiple wrapper containers, the last key contains the actual resource to decode
    ///   - cacheKey: The `cacheKey` is used to identify the object in the cache
    ///   - cachePolicy: The `cachePolicy` defines strategies how a resource is cached and which resource is returned (cache/network)
    ///   - cacheGroup: The `cacheGroup` can be used to group resources into cache groups. If a resource
    ///     performs a network request using an altering HTTP method (.post, .patch, .put, .delete) the cache associated with the
    ///     resource's cache group is removed
    ///   - cacheExpiration: The `cacheExpiration` speficies when a resource's cached value is marked as expired
    ///   - multipartFormData: The `multipartFormData` closure can be used construct multipart form-data
    ///   - shouldStub: Indicates if requests should be stubbed, if nil uses the global `shouldStub` from the `APIClient`
    ///   - stub: If stubbing is enabled the `stub` is used to replace the network response. The actual network request is not performed.
    ///   - decode: The `decode` closure replaces the default decoding behaviour
    ///   - encode: The `encode` closure replaces the default encoding behaviour
    public init(apiClient: APIClient = APIClient.shared,
                headers: HTTPHeaders? = nil,
                method: HTTPMethod = .get,
                baseURL: URL? = nil,
                path: String,
                urlParameters: Parameters? = nil,
                body: Encodable? = nil,
                rootKeys: [String]? = nil,
                cacheKey: String? = nil,
                cachePolicy: CachePolicy? = nil,
                cacheGroup: String? = nil,
                cacheExpiration: Expiration? = nil,
                multipartFormData: MultipartFormData? = nil,
                shouldStub: Bool? = nil,
                stub: Stub? = nil,
                decode: DecodingClosure? = nil,
                encode: EncodingClosure? = nil) {
        self.apiClient = apiClient
        self.headers = headers
        self.method = method
        self.baseURL = baseURL
        self.path = path
        self.urlParameters = urlParameters
        self.body = body
        self.rootKeys = rootKeys
        self.customCacheKey = cacheKey
        self.cachePolicy = cachePolicy
        self.cacheGroup = cacheGroup
        self.cacheExpiration = cacheExpiration
        self.multipartFormData = multipartFormData
        self.shouldStub = shouldStub
        self.stub = stub
        
        if let decode = decode {
            self.decode = decode
        } else {
            self.decode = { (data) -> T in
                if let rootKeys = rootKeys, let keyDecoder = apiClient.config.decoder as? ResourceRootKeyDecoderProtocol {
                    return try keyDecoder.decode(T.self, from: data, keyedBy: rootKeys)
                } else {
                    return try apiClient.config.decoder.decode(T.self, from: data)
                }
            }
        }
        
        if let encode = encode {
            self.encode = encode
        } else {
            self.encode = { (encodable) -> (Data, HTTPContentType?) in
                let data = try apiClient.config.encoder.encode(AnyEncodable(encodable))
                return (data, .json)
            }
        }
    }
    
    // MARK: URLRequestConvertible
    
    public func asURLRequest() throws -> URLRequest {
        // Merge defaultHeaders and http headers of resource (resource overrides defaultHeaders)
        let resourceHeaders = headers?.dictionary ?? [:]
        var headers = apiClient.config.defaultHeaders.dictionary.merging(resourceHeaders) { (_, new) in new }
        
        // Add request is as http header for stubbing
        if let stub = stubIfNeeded {
            headers[StubbedURL.stubIdHeader] = stub.id.uuidString
        }
        
        // Create request from resource
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = headers
        
        // Body
        if let body = body {
            let (data, contentType) = try encode(body)
            urlRequest.httpBody = data
            if let contentType = contentType {
                 urlRequest.addValue(contentType.description, forHTTPHeaderField: "Content-Type")
            }
        }
        
        // URL parameter
        let urlEncoding = URLEncoding(destination: .queryString)
        if let urlParameters = urlParameters {
            urlRequest = try urlEncoding.encode(urlRequest, with: urlParameters)
        }
        
        return urlRequest
    }
    
    // MARK: Caching
    
    private func computeCacheKey() -> String {
        var str = url.absoluteString
        
        if let urlParameters = urlParameters, urlParameters.count > 0 {
            str.append("urlParameters:")
            let sorted = urlParameters.sorted(by: { $0.key < $1.key })
            for (key, value) in sorted {
                str += "\(key)=\(value) "
            }
        }
        
        if let rootKeys = rootKeys, rootKeys.count > 0 {
            str.append("rootKeys:" + rootKeys.joined(separator: ","))
        }
        
        return str.sha1 ?? ""
    }
}

// MARK: - Request

public extension Resource {
    
    /// Performs a network request on the resource
    ///
    /// - Parameters:
    ///   - queue: The `DispatchQueue` on which the completion closure is called
    ///   - completion: Is called when the network request succeeds with an `NetworkResponse` or fails with an `FetchError`
    ///   - result: The `Result` of the network request
    /// - Returns: A `RequestToken` to cancel the request
    ///
    /// If the HTTP method of the resource is .post, .patch, .put or .delete the corresponding cache groups are removed
    /// IF YOU WANT TO STUB YOU NEED TO EXECUTE THE REQUEST ON THE RESOURCE(APICLIENT) NOT THE SESSION
    @discardableResult func request(queue: DispatchQueue = .main, completion: @escaping (_ result: Swift.Result<NetworkResponse<T>, FetchError>) -> Void) -> RequestToken? {
        return apiClient.request(self, queue: queue) { [weak self] (result) in
            defer { completion(result) }
            
            guard let self = self else {
                return
            }
            
            switch self.method {
            case .post, .patch, .put, .delete:
                if let cache = self.cache, let group = self.cacheGroup {
                    do {
                        try cache.remove(group: group)
                    } catch {
                        print("cache error: \(error)")
                    }
                }
            default:
                break
            }
        }
    }
}

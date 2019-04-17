//
//  FetchError.swift
//  Fetch
//
//  Created by Matthias Buchetics on 17.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Alamofire

/// The `FetchError` represents a possible error during a network request, the decoding of the response body and the caching
public enum FetchError: Error {
    
    /// Indicating an error during the network request
    ///
    /// - error: The `AFError` provided by Alamofire
    /// - responseData: The `Data` representing the http response body
    case network(error: AFError, responseData: Data?)
    
    /// Indicating an error during the decoding of the http response body
    ///
    /// - error: The resulting `DecodingError`
    case decoding(error: DecodingError)
    
    /// Indicating that the `HTTPURLResponse` is `nil` or invalid
    case invalidResponse
    
    /// Indicating that no cache was found for the resource (only for the `cacheOnly` cache policy)
    case cacheNotFound
    
    /// Indicating any other error during the process
    ///
    /// - error: The other error
    case other(error: Error)
}

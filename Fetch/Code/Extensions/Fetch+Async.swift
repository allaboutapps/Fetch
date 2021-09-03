//
//  Fetch+Async.swift
//  Fetch+Async
//
//  Created by Matthias Buchetics on 01.09.21.
//  Copyright © 2021 aaa - all about apps GmbH. All rights reserved.
//

#if swift(>=5.5)

import Foundation

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension Resource {
    
    func requestAsync() async throws -> NetworkResponse<T> {
        var requestToken: RequestToken?
        
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            
            return try await withCheckedThrowingContinuation { (continuation) in
                requestToken = self.request(queue: .asyncCompletionQueue) { (result) in
                    switch result {
                    case let .success(response):
                        continuation.resume(returning: response)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
            }
          } onCancel: { [requestToken] in
              requestToken?.cancel() // runs immediately when cancelled
          }
    }
    
    // this will only return the first available response (given the specified cache policy), e.g. the cached model but NOT the updated model from the network
    func fetchAsync(cachePolicy: CachePolicy? = nil) async throws -> FetchResponse<T> where T: Cacheable {
        var requestToken: RequestToken?
        
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            
            return try await withCheckedThrowingContinuation { (continuation) in
                requestToken = self.fetch(cachePolicy: cachePolicy, queue: .asyncCompletionQueue) { (result, _) in
                    switch result {
                    case let .success(response):
                        continuation.resume(returning: response)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
            }
          } onCancel: { [requestToken] in
              requestToken?.cancel() // runs immediately when cancelled
          }
    }
}

#endif

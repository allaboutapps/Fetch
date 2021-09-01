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
        return try await withCheckedThrowingContinuation { (continuation) in
            self.request(queue: DispatchQueue.asyncCompletionQueue) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // this will only return the first available response (given the specified cache policy), e.g. the cached model but NOT the updated model from the network
    func fetchAsync(cachePolicy: CachePolicy? = nil) async throws -> FetchResponse<T> where T: Cacheable {
        return try await withCheckedThrowingContinuation { (continuation) in
            self.fetch(cachePolicy: cachePolicy, queue: DispatchQueue.asyncCompletionQueue) { (result, _) in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

#endif

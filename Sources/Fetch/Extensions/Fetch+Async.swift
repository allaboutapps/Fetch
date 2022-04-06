//
//  Fetch+Async.swift
//  Fetch+Async
//
//  Created by Matthias Buchetics on 01.09.21.
//  Copyright © 2021 aaa - all about apps GmbH. All rights reserved.
//

#if swift(>=5.5.2)

import Foundation

@available(macOS 12, iOS 13, tvOS 15, watchOS 8, *)
public extension Resource {
    
    enum ForwardBehaviour {
        case firstValue
        case waitForFinishedValue
    }
    
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
    
    func fetchAsync(cachePolicy: CachePolicy? = nil, behaviour: ForwardBehaviour = .firstValue) async throws -> (FetchResponse<T>, Bool) where T: Cacheable {
        var requestToken: RequestToken?
        
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            
            return try await withCheckedThrowingContinuation { (continuation) in
                var hasSendOneValue = false
                requestToken = self.fetch(cachePolicy: cachePolicy, queue: .asyncCompletionQueue) { (result, isFinished) in
                    guard !hasSendOneValue else { return }
                    
                    switch result {
                    case let .success(response):
                        
                        let sendValue = {
                            continuation.resume(returning: (response, isFinished))
                            hasSendOneValue = true
                        }
                        
                        switch (behaviour, isFinished) {
                        case (.firstValue, _):
                            sendValue()
                        case (.waitForFinishedValue, true):
                            sendValue()
                        default:
                            break
                        }
                        
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
            }
          } onCancel: { [requestToken] in
              requestToken?.cancel() // runs immediately when cancelled
          }
    }
    
    func fetchAsyncSequence(cachePolicy: CachePolicy? = nil) -> AsyncThrowingStream<FetchResponse<T>, Error> where T: Cacheable {
        return AsyncThrowingStream<FetchResponse<T>, Error> { continuation in
            
            let requestToken = self.fetch(cachePolicy: cachePolicy, queue: .main) { (result, isFinished) in
                switch result {
                case let .success(response):
                    continuation.yield(response)
                    if isFinished {
                        continuation.finish(throwing: nil)
                    }
                case let .failure(error):
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled:
                    requestToken.cancel()
                default:
                    break
                }
            }
        }
    }
}

#endif

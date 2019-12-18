//
//  Fetch+Combine.swift
//  Fetch
//
//  Created by Matthias Buchetics on 18.12.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

#if canImport(Combine)

import Foundation
import Combine

// MARK: - FetchPublisher

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class FetchPublisher<Output>: Publisher {

    internal typealias Failure = FetchError

    private class Subscription: Combine.Subscription {

        private let cancellable: Cancellable?

        init(subscriber: AnySubscriber<Output, FetchError>, callback: @escaping (AnySubscriber<Output, FetchError>) -> Cancellable?) {
            self.cancellable = callback(subscriber)
        }

        func request(_ demand: Subscribers.Demand) {
            // We don't care for the demand right now
        }

        func cancel() {
            cancellable?.cancel()
        }
    }

    private let callback: (AnySubscriber<Output, FetchError>) -> Cancellable?

    init(callback: @escaping (AnySubscriber<Output, FetchError>) -> Cancellable?) {
        self.callback = callback
    }

    internal func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = Subscription(subscriber: AnySubscriber(subscriber), callback: callback)
        subscriber.receive(subscription: subscription)
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension RequestToken: Cancellable { }

// MARK: - Resource+Request

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Resource {
    
    func requestPublisher(callbackQueue: DispatchQueue = .main) -> AnyPublisher<NetworkResponse<T>, FetchError> {
        return FetchPublisher { (subscriber) in
            return self.request(queue: callbackQueue) { (result) in
                switch result {
                case let .success(response):
                    _ = subscriber.receive(response)
                    subscriber.receive(completion: .finished)
                case let .failure(error):
                    subscriber.receive(completion: .failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func requestModel(callbackQueue: DispatchQueue = .main) -> AnyPublisher<T, FetchError> {
        return requestPublisher(callbackQueue: callbackQueue)
            .map { $0.model }
            .eraseToAnyPublisher()
    }
}

// MARK: - Resource+Fetch

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Resource where T: Cacheable {
    
    func fetchPublisher(cachePolicy: CachePolicy? = nil, callbackQueue: DispatchQueue = .main) -> AnyPublisher<FetchResponse<T>, FetchError> {
        return FetchPublisher { (subscriber) in
            return self.fetch(cachePolicy: cachePolicy, queue: callbackQueue) { (result, isFinished) in
                switch result {
                case let .success(response):
                    _ = subscriber.receive(response)
                    if isFinished {
                        subscriber.receive(completion: .finished)
                    }
                case let .failure(error):
                    subscriber.receive(completion: .failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func fetchModel(callbackQueue: DispatchQueue = .main) -> AnyPublisher<T, FetchError> {
        return fetchPublisher(callbackQueue: callbackQueue)
            .map { $0.model }
            .eraseToAnyPublisher()
    }
}

#endif

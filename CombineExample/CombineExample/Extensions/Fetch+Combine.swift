//
//  Fetch+Combine.swift
//  CombineExample
//
//  Created by Matthias Buchetics on 18.12.19.
//  Copyright © 2019 allaboutapps GmbH. All rights reserved.
//

import Foundation
import Combine
import Fetch

internal class FetchPublisher<Output>: Publisher {

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

//
//  ReactiveFetch.swift
//  Example
//
//  Created by Michael Heinzl on 09.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import ReactiveSwift
import Fetch

// MARK: - Request

extension Resource {
    
    func request() -> SignalProducer<NetworkResponse<T>, FetchError> {
        return SignalProducer { (observer, lifetime) in
            let strongSelf = self
            let token = strongSelf.request { (result) in
                switch result {
                case .success(let response):
                    observer.send(value: response)
                    observer.sendCompleted()
                case .failure(let error):
                    observer.send(error: error)
                }
            }
            
            lifetime.observeEnded {
                token?.cancel()
            }
        }
    }
    
    func requestModel() -> SignalProducer<T, FetchError> {
        return request().map { $0.model }
    }
}

// MARK: - Fetch

extension Resource where T: Cacheable {
    
    func fetch(cachePolicy: CachePolicy? = nil) -> SignalProducer<FetchResponse<T>, FetchError> {
        return SignalProducer { (observer, lifetime) in
            let strongSelf = self
            let token = strongSelf.fetch(cachePolicy: cachePolicy) { (result, isFinished) in
                switch result {
                case .success(let response):
                    observer.send(value: response)
                    if isFinished {
                        observer.sendCompleted()
                    }
                case .failure(let error):
                    observer.send(error: error)
                }
            }
            
            lifetime.observeEnded {
                token.cancel()
            }
        }
    }
    
    func fetchModel(cachePolicy: CachePolicy? = nil) -> SignalProducer<T, FetchError> {
        return fetch(cachePolicy: cachePolicy).map { $0.model }
    }
}

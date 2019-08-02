//
//  Resource+Combine.swift
//  CombineExample
//
//  Created by Stefan Wieland on 02.08.19.
//  Copyright © 2019 allaboutapps GmbH. All rights reserved.
//

import Combine
import Fetch

// MARK: - Request

public extension Resource {
    
    func requestNetworkResponse() -> AnyPublisher<NetworkResponse<T>, FetchError> {
        let subject = PassthroughSubject<NetworkResponse<T>, FetchError>()
        let token = self.request { (result) in
            switch result {
            case .success(let response):
                subject.send(response)
                subject.send(completion: .finished)
            case .failure(let error):
                subject.send(completion: .failure(error))
            }
        }
        
        return subject
            .handleEvents(receiveCancel: {
                token?.cancel()
            })
            .eraseToAnyPublisher()
    }
    
    func requestModel() -> AnyPublisher<T, FetchError> {
        return requestNetworkResponse()
            .map({ $0.model })
            .eraseToAnyPublisher()
    }
    
}

// MARK: - Fetch

public extension Resource where T: Cacheable {

    func fetchResponse(cachePolicy: CachePolicy? = nil) -> AnyPublisher<FetchResponse<T>, FetchError> {
        let subject = PassthroughSubject<FetchResponse<T>, FetchError>()
        let token = self.fetch(cachePolicy: cachePolicy) { (result, isFinished) in
            switch result {
            case .success(let response):
                subject.send(response)
                if isFinished {
                    subject.send(completion: .finished)
                }
            case .failure(let error):
                subject.send(completion: .failure(error))
            }
        }
        
        return subject.handleEvents(receiveCancel: {
            token.cancel()
        }).eraseToAnyPublisher()
    }
    
    func fetchModel(cachePolicy: CachePolicy? = nil) -> AnyPublisher<T, FetchError> {
        return fetchResponse(cachePolicy: cachePolicy)
            .map({ $0.model })
            .eraseToAnyPublisher()
    }
    
}


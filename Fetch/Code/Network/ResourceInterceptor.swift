//
//  ResourceInterceptor.swift
//  Fetch
//
//  Created by Oliver Krakora on 23.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Alamofire

public protocol ResourceAdapter {
    func adapt<T>(resource: Resource<T>, request: URLRequest, client: APIClient, handler: @escaping ((Result<T, Error>) -> Void))
}

public protocol ResourceRetrier {
    func retry<T>(resource: Resource<T>, client: APIClient, error: Error, completion: @escaping ((Alamofire.RetryResult) -> Void))
}

public protocol ResourceInterceptor: ResourceAdapter, ResourceRetrier { }

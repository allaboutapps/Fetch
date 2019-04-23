//
//  ResourceInterceptor.swift
//  Fetch
//
//  Created by Oliver Krakora on 23.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Alamofire

protocol ResourceAdapter {
    func adapt(request: inout URLRequest, client: APIClient)
}

protocol ResourceRetrier {
    func retry<T>(request: Alamofire.Request, resource: Resource<T>, client: APIClient, completion: @escaping (Alamofire.RetryResult) -> Void)
}

protocol ResourceInterceptor: ResourceAdapter, ResourceRetrier { }

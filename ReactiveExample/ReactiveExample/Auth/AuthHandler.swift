//
//  AuthHandler.swift
//  Fetch
//
//  Created by Michael Heinzl on 04.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Alamofire
import Fetch

class AuthHandler: RequestInterceptor {
    
    private typealias RefreshCompletion = (_ succeeded: Bool, _ credentials: Credentials?) -> Void
    private typealias RequestRetryCompletion = (Alamofire.RetryResult) -> Void
    
    private static let apiLogger = APILogger(verbose: true)
    
    private let session: Session = {
        let configuration = URLSessionConfiguration.default
        return Session(configuration: configuration, eventMonitors: [apiLogger])
    }()
    
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "network.auth.queue")
    private var isRefreshing = false
    private var requestsToRetry: [RequestRetryCompletion] = []
    
    // MARK: - RequestAdapter
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (AFResult<URLRequest>) -> Void) {
        var urlRequest = urlRequest
        if let accessToken = CredentialsController.shared.currentCredentials?.accessToken {
            urlRequest.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        }
        completion(.success(urlRequest))
    }
    
    // MARK: - RequestRetrier
    
    func retry(_ request: Alamofire.Request, for session: Alamofire.Session, dueTo error: Error, completion: @escaping (Alamofire.RetryResult) -> Void) {
        lock.lock() ; defer { lock.unlock() }
        
        guard let response = request.task?.response as? HTTPURLResponse,
            let refreshToken = CredentialsController.shared.currentCredentials?.refreshToken,
            response.statusCode == 401 else {
                completion(.doNotRetry)
                return
        }
        
        requestsToRetry.append(completion)
        
        if !isRefreshing {
            refreshCredentials(refreshToken) { [weak self] (succeeded, credentials) in
                guard let self = self else { return }
                
                self.lock.lock() ; defer { self.lock.unlock() }
                
                if let credentials = credentials {
                    CredentialsController.shared.currentCredentials = credentials
                }
                
                if succeeded {
                    self.requestsToRetry.forEach { $0(.retry) }
                } else {
                    self.requestsToRetry.forEach { $0(.doNotRetry) }
                }
                
                self.requestsToRetry.removeAll()
            }
        }
    }
    
    // MARK: - Private - Refresh Tokens
    
    private func refreshCredentials(_ refreshToken: String, completion: @escaping RefreshCompletion) {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        guard let urlRequest = try? API.Auth.tokenRefresh(refreshToken).asURLRequest() else {
            completion(false, nil)
            return
        }
        
        session
            .request(urlRequest)
            .responseDecodable(queue: queue, completionHandler: { [weak self] (response: DataResponse<Credentials>) in
                guard let self = self else { return }
                switch response.result {
                case .success(let credentials):
                    completion(true, credentials)
                case .failure:
                    completion(false, nil)
                }
                self.isRefreshing = false
            })
    }
    
}

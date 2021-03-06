import Foundation
import Alamofire
import Fetch

public class AuthHandler: RequestInterceptor {
    
    private typealias RefreshCompletion = (_ succeeded: Bool, _ credentials: Credentials?) -> Void
    private typealias RequestRetryCompletion = (Alamofire.RetryResult) -> Void
    
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "network.auth.queue")
    private var isRefreshing = false
    private var requestsToRetry: [RequestRetryCompletion] = []
    
    // MARK: - RequestAdapter
    
    public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (AFResult<URLRequest>) -> Void) {
        var urlRequest = urlRequest
        if let accessToken = CredentialsController.shared.currentCredentials?.accessToken {
            urlRequest.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        }
        completion(.success(urlRequest))
    }
    
    // MARK: - RequestRetrier
    
    public func retry(_ request: Alamofire.Request, for session: Session, dueTo error: Error, completion: @escaping (Alamofire.RetryResult) -> Void) {
        lock.lock() ; defer { lock.unlock() }
        
        guard let response = request.task?.response as? HTTPURLResponse,
            let refreshToken = CredentialsController.shared.currentCredentials?.refreshToken,
            response.statusCode == 401 else {
                completion(.doNotRetry)
                return
        }
        
        requestsToRetry.append(completion)
        
        if !isRefreshing {
            refreshCredentials(refreshToken, session: session) { [weak self] (succeeded, credentials) in
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
    
    private func refreshCredentials(_ refreshToken: String, session: Session, completion: @escaping RefreshCompletion) {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        API.StubbedAuth.tokenRefresh(refreshToken).request { result in
            switch result {
            case .success(let credentials):
                completion(true, credentials.model)
            case .failure:
                completion(false, nil)
            }
        }
    }
}

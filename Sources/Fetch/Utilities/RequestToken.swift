//
//  RequestToken.swift
//  Fetch
//
//  Created by Michael Heinzl on 09.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

/// A `RequestToken` can be used to cancel a running network request
public class RequestToken {
    public let onCancel: (() -> Void)
    private var requestTokens = [RequestToken]()
    
    /// Indicates if the request is cancelled
    public private(set) var isCancelled: Bool = false
    
    public init(_ onCancel: @escaping (() -> Void) = {}) {
        self.onCancel = onCancel
    }
    
    /// Appends a `RequestToken` and cancels it if self is already cancelled
    public func append(_ requestToken: RequestToken) {
        requestTokens.append(requestToken)
        
        if isCancelled {
            requestToken.cancel()
        }
    }
    
    @discardableResult
    public static func += (lhs: RequestToken, rhs: RequestToken) -> RequestToken {
        lhs.append(rhs)
        return lhs
    }
    
    /// Cancels the corresponding request if not already cancelled
    public func cancel() {
        if !isCancelled {
            requestTokens.forEach { $0.cancel() }
            isCancelled = true
            onCancel()
        }
    }
}

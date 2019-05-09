//
//  ClosureStub.swift
//  Fetch
//
//  Created by Oliver Krakora on 24.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

public struct ClosureStub: Stub {
    
    public typealias StubClosure = (() -> Stub)
    
    public let stubClosure: StubClosure
    
    public var result: Result<(StatusCode, Data), Error> {
        return stubClosure().result
    }
    
    public let id: UUID = UUID()
    
    public var delay: TimeInterval {
        return stubClosure().delay
    }
    
    public init(stubClosure: @escaping StubClosure) {
        self.stubClosure = stubClosure
    }
}

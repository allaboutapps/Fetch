//
//  StubProvider.swift
//  Fetch
//
//  Created by Stefan Wieland on 09.12.21.
//  Copyright © 2021 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

public typealias ResourceStubKey = String

/// StubProvider does hold all registered stubs and provide it if needed by resource
public protocol StubProvider {
    
    func stub(for resourceStubKey: ResourceStubKey) -> Stub?
    
    func register(stub: Stub, for resourceStubKey: ResourceStubKey)
    
    func remove(stub: Stub)
    
//    func removeAllStubs(from resource: Resource)
    
}

public class DefaultStubProvider: StubProvider {
    
    private var store = [ResourceStubKey: Stub]()
    
    public init() { }

    public func stub(for resourceStubKey: ResourceStubKey) -> Stub? {
        return store[resourceStubKey]
    }
    
    public func register(stub: Stub, for resourceStubKey: ResourceStubKey) {
        store[resourceStubKey] = stub
    }
    
    public func remove(stub: Stub) {
    }
    
}

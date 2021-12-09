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
    
    func register<T>(stub: Stub, for resource: Resource<T>)
    
    func remove(stub: Stub)
    
    func removeStub<T>(for resource: Resource<T>)
    
    func stub<T>(for resource: Resource<T>) -> Stub?
    
}

public class DefaultStubProvider: StubProvider {
    
    private var store = [ResourceStubKey: Stub]()
    
    public init() { }

    public func stub<T>(for resource: Resource<T>) -> Stub? {
        return store[resource.stubKey]
    }
    
    public func register<T>(stub: Stub, for resource: Resource<T>) {
        store[resource.stubKey] = stub
    }
    
    public func remove(stub: Stub) {
        guard let element = store.first(where: { $0.value.id == stub.id }) else { return }
        store[element.key] = nil
    }
    
    public func removeStub<T>(for resource: Resource<T>) {
        store[resource.stubKey] = nil
    }
    
}

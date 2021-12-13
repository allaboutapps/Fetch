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
    
    /// Register a stub for a given resource
    /// Existing stub for given resource will be replaced
    ///
    /// - Parameters:
    ///     - stub: A stub confirming to Stub protocol
    ///     - resource: Stub will be registered for this resource
    func register<T>(stub: Stub, for resource: Resource<T>)
    
    /// Register a stub for a custom stubKey
    /// Existing stub for given stubKey will be replaced
    ///
    /// - Parameters:
    ///     - stub: A stub confirming to Stub protocol
    ///     - stubKey: Stub will be registered for this stubKey
    ///
    /// Also set the same stubKey on `Resource<T>`
    func register(stub: Stub, forStubKey stubKey: ResourceStubKey)
    
    /// Remove all registered stubs in provider
    func removeAll()
    
    /// Remove registered stub for given resource
    ///
    /// - Parameter resource: Resource
    func removeStub<T>(for resource: Resource<T>)
    
    /// Remove registered stub for given stubKey
    ///
    /// - Parameter resource: Resource
    func removeStub(forStubKey stubKey: ResourceStubKey)
    
    /// Return stub for given resource
    ///
    /// - Parameter resource: Resource
    /// - returns: Stub if registered
    func stub<T>(for resource: Resource<T>) -> Stub?
    
    /// Return stub for given stubKey
    ///
    /// - Parameter stubKey: A key to retrieve a stub
    /// - returns: Stub if registered
    func stub(for stubKey: ResourceStubKey) -> Stub?
    
}

// MARK: - DefaultStubProvider

public class DefaultStubProvider: StubProvider {
    
    private var store = [ResourceStubKey: Stub]()
    
    public init() { }

    public func register<T>(stub: Stub, for resource: Resource<T>) where T: Decodable {
        store[resource.stubKey] = stub
    }
    
    public func register(stub: Stub, forStubKey stubKey: ResourceStubKey) {
        store[stubKey] = stub
    }
    
    public func removeStub<T>(for resource: Resource<T>) {
        removeStub(forStubKey: resource.stubKey)
    }
    
    public func removeStub(forStubKey stubKey: ResourceStubKey) {
        store[stubKey] = nil
    }
    
    public func removeAll() {
        store.removeAll()
    }
        
    public func stub<T>(for resource: Resource<T>) -> Stub? {
        stub(for: resource.stubKey)
    }
    
    public func stub(for stubKey: ResourceStubKey) -> Stub? {
        store[stubKey]
    }
    
}

//
//  AlternatingStub.swift
//  Fetch
//
//  Created by Michael Heinzl on 10.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

/// A `Stub` representing a list of `Stubs`.
/// The `AlternatingStub` cycles through the list.
/// The index is increased after `result` is called.
public class AlternatingStub: Stub {
    
    let stubs: [Stub]
    
    /// Initializes a new `AlternatingStub`
    ///
    /// - Parameter stubs: The list of `Stubs` which is cycled through
    public init(stubs: [Stub]) {
        self.stubs = stubs
    }
    
    /// The id of the current stub
    public var id: UUID {
        return currentStub.id
    }
    
    /// The delay of the current stub
    public var delay: TimeInterval {
        return currentStub.delay
    }
    
    public internal(set) var index: Int = 0
    
    internal func setNextIndex() {
        index = (index + 1) % stubs.count
    }
    
    /// The `Result` of the current stub
    public var result: Result<(StatusCode, Data), Error> {
        let stub = currentStub.result
        setNextIndex()
        return stub
    }
    
    /// The `Result` of the current stub
    var currentStub: Stub {
        return stubs[index]
    }
    
}

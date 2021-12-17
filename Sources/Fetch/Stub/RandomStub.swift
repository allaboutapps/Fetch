//
//  RandomStub.swift
//  Fetch
//
//  Created by Michael Heinzl on 10.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

/// A `Stub` representing a list of `Stubs`.
/// It returnes a random stub from the list each time `result` is called.
public class RandomStub: AlternatingStub {
    
    override internal func setNextIndex() {
        index = Int.random(in: 0..<stubs.count)
    }
    
}

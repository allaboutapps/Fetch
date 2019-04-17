//
//  MemoryCacheTests.swift
//  FetchTests
//
//  Created by Matthias Buchetics on 09.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import XCTest
import Alamofire

@testable
import Fetch

class MemoryCacheTests: CacheTests {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    override func createCache() -> Cache {
        return MemoryCache(defaultExpiration: .seconds(10.0))
    }
}

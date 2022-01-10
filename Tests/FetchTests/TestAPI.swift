//
//  TestAPI.swift
//  FetchTests
//
//  Created by Michael Heinzl on 05.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Fetch

struct ModelA: Equatable, Cacheable {
    let a: String
}

struct ModelB: Equatable, Cacheable {
    let b: String
}

//
//  IgnoreBody.swift
//  Fetch
//
//  Created by Michael Heinzl on 17.05.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

/// IgnoreBody can be used as the generic type of a `Resource` to ignore the HTTP response body
/// i.e. the body data is not decoded
public struct IgnoreBody: Decodable {
    
    internal init() {}
    
}

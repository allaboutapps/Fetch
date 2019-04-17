//
//  AnyEncodable.swift
//  ExampleKit
//
//  Created by Matthias Buchetics on 24.09.18.
//  Copyright © 2018 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

public struct AnyEncodable: Encodable {
    
    private let encodable: Encodable
    
    public init(_ encodable: Encodable) {
        self.encodable = encodable
    }
    
    public func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}

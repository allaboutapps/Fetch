//
//  ResourceDecoderProtocol.swift
//  Fetch
//
//  Created by Oliver Krakora on 12.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

public protocol ResourceDecoderProtocol {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

public protocol ResourceRootKeyDecoderProtocol: ResourceDecoderProtocol {
    func decode<T: Decodable>(_ type: T.Type, from data: Data, keyedBy key: [String]) throws -> T
}

//
//  PageableProtocol.swift
//  Fetch
//
//  Created by Oliver Krakora on 12.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

public protocol PageProtocol: Decodable {
    associatedtype Item: Decodable
    
    var hasNext: Bool { get }
    
    var items: [Item] { get }
}

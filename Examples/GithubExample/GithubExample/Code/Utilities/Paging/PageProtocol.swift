//
//  PageableProtocol.swift
//  Fetch
//
//  Created by Oliver Krakora on 12.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

protocol PageProtocol: Decodable {
    associatedtype Item: Decodable
    
    var offset: Int { get }
    var limit: Int { get }
    var total: Int { get }
    var items: [Item] { get }
}

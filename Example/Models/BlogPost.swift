//
//  Post.swift
//  Fetch
//
//  Created by Michael Heinzl on 02.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Fetch

public struct BlogPost: Codable, Equatable {
    public let id: Int
    public let title: String
    public let author: String
    
    public init(id: Int, title: String, author: String) {
        self.id = id
        self.title = title
        self.author = author
    }
}

extension BlogPost: Cacheable { }

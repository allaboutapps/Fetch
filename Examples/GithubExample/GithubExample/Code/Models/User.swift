//
//  User.swift
//  GithubExample
//
//  Created by Oliver Krakora on 12.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Fetch

struct User: Equatable, Cacheable {
    
    private enum CodingKeys: String, CodingKey {
        case username = "login"
        case id
        case avatarURL = "avatar_url"
        case url
        
    }
    
    let username: String
    let id: Int
    let avatarURL: URL?
    let url: URL
}

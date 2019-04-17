//
//  Organization.swift
//  Example
//
//  Created by Oliver Krakora on 12.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Fetch

struct Organization: Equatable, Cacheable {
    
    private enum CodingKeys: String, CodingKey {
        case id
        case url
        case avatarURL = "avatar_url"
        case description
        case name
        case location
        case email
        case blogURL = "blog"
        case publicRepositoryCount = "public_repos"
    }
    
    let id: Int
    let url: URL
    let avatarURL: URL?
    let name: String
    let location: String?
    let description: String?
    let blogURL: URL?
    let email: String?
    let publicRepositoryCount: Int
}

//
//  Repository.swift
//  GithubExample
//
//  Created by Oliver Krakora on 12.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Fetch

struct Repository: Equatable, Cacheable {
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case url = "html_url"
        case description
        case language
        case forkCount = "forks_count"
        case stars = "stargazers_count"
        case watchers = "watchers"
    }
    
    let id: Int
    let name: String
    let fullName: String
    let url: URL
    let description: String?
    let language: String?
    let forkCount: Int
    let stars: Int
    let watchers: Int
}

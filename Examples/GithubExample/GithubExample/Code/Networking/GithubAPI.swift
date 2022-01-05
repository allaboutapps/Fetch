//
//  GithubAPI.swift
//  Example
//
//  Created by Oliver Krakora on 12.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Fetch

struct GithubAPI {
    
    struct Org {
        
        static func organization(with username: String) -> Resource<Organization> {
            return Resource(path: "orgs/\(username)")
        }
        
        static func members(for organizationName: String) -> Resource<[User]> {
            return Resource(path: "orgs/\(organizationName)/members")
        }
        
        static func repositories(for organizationName: String) -> Resource<[Repository]> {
            return Resource(path: "orgs/\(organizationName)/repos")
        }
    }
}

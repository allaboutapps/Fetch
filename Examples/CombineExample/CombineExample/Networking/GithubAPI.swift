//
//  GithubAPI.swift
//  CombineExample
//
//  Created by Stefan Wieland on 02.08.19.
//  Copyright © 2019 allaboutapps GmbH. All rights reserved.
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

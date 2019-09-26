//
//  API.swift
//  Fetch
//
//  Created by Michael Heinzl on 02.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Alamofire
import Fetch

public struct API {
    
    static func setup() {
        let config = Fetch.Config(baseURL: URL(string: "https://yoururlhere.com")!)
        APIClient.shared.setup(with: config)
    }
    
    struct Basics {
        static func organization(with username: String) -> Resource<Organization> {
            return Resource(
                baseURL: URL(string: "https://api.github.com")!,
                path: "orgs/\(username)")
        }
        
    }
    
    struct Stubbing {
        static func stubbedPerson(with stub: Stub) -> Resource<Person> {
            return Resource(
                path: "/person",
                shouldStub: true,
                stub: stub
            )
        }
    }
}

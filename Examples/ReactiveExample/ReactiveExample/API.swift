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
    
    public struct StubbedAuth {
        
        static let baseURL = URL(string: "")
        
        public static func login(username: String, password: String) -> Resource<Credentials> {
            Resource(
                method: .post,
                baseURL: baseURL,
                path: "/api/v1/auth/login",
                body: .encodable([
                    "username": username,
                    "password": password
                ]))
        }
        
        public static func tokenRefresh(_ refreshToken: String) -> Resource<Credentials> {
            Resource(
                method: .post,
                baseURL: baseURL,
                path: "/api/v1/auth/refresh",
                body: .encodable([
                    "refreshToken": refreshToken
                ]))
        }
        
        public static func authorizedRequest() -> Resource<Data> {
            Resource(path: "/auth/secret")
        }
        
        public static func unauthorizedErrorRequest() -> Resource<Data> {
            Resource(path: "/fail")
        }
    }
    
    public struct BlogPosts {
        
        public static func list() -> Resource<[BlogPost]> {
            Resource(method: .get, path: "/posts")
        }
    }
}

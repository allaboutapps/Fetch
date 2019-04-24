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
            return Resource(
                method: .post,
                baseURL: baseURL,
                path: "/api/v1/auth/login",
                body: [
                    "username": username,
                    "password": password
                ], shouldStub: true,
                stub: StubResponse(statusCode: 200, fileName: "authresponse.json", delay: 3))
        }
        
        public static func tokenRefresh(_ refreshToken: String) -> Resource<Credentials> {
            return Resource(
                method: .post,
                baseURL: baseURL,
                path: "/api/v1/auth/refresh",
                body: [
                    "refreshToken": refreshToken
                ], shouldStub: true,
                stub: StubResponse(statusCode: 200, fileName: "authresponse.json", delay: 4))
        }
        
        public static func authorizedRequest() -> Resource<Data> {
            let conditionalStub = ClosureStub { () -> Stub in
                let unauthorizedStub = StubResponse(statusCode: 401, data: Data(), delay: 2)
                let okStub = StubResponse(statusCode: 200, data: Data(), delay: 2)
                return CredentialsController.shared.currentCredentials == nil ? unauthorizedStub : okStub
            }
            
            return Resource(
                path: "/auth/secret",
                shouldStub: true,
                stub: conditionalStub
            )
        }
        
        public static func unauthorizedErrorRequest() -> Resource<Data> {
            let failingStub = StubResponse(statusCode: 401, data: Data(), delay: 2)
            let okStub = StubResponse(statusCode: 200, data: Data(), delay: 2)
            
            return Resource(
                path: "/fail",
                shouldStub: true,
                stub: AlternatingStub(stubs: [failingStub, okStub])
            )
        }
    }
    
    public struct BlogPosts {
        
        public static func list() -> Resource<[BlogPost]> {
            return Resource(
                method: .get,
                path: "/posts",
                shouldStub: true,
                stub: StubResponse(statusCode: 200, fileName: "posts.json", delay: 1))
        }
    }
}

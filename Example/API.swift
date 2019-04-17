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
    
    public struct BlogPosts {
        
        public static func list() -> Resource<[BlogPost]> {
            return Resource(
                method: .get,
                path: "/posts")
        }
        
        public static func detail(id: Int) -> Resource<BlogPost> {
            return Resource(
                method: .get,
                path: "/posts/\(id)")
        }
        
        public static func create(_ post: BlogPost) -> Resource<BlogPost> {
            return Resource(
                method: .post,
                path: "/posts",
                body: [
                    "title": post.title,
                    "author": post.author
                ])
        }
        
        public static func nestedTest() -> Resource<BlogPost> {
            return Resource(
                method: .get,
                path: "/mocked",
                rootKeys: ["super", "deep", "nesting"],
                shouldStub: true,
                stub: StubResponse(statusCode: 200, filename: "nested-post.json", delay: 1))
        }
    }

    public static func getEmpty() -> Resource<Empty> {
        return Resource(
            method: .get,
            path: "/posts")
    }
}

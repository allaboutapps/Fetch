//
//  PagedResource.swift
//  Fetch
//
//  Created by Oliver Krakora on 12.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Fetch

class PagedResource<Page: PageProtocol> {
    
    typealias PageResourceConstructor = ((Resource<Page>, Page) -> Resource<Page>)
    
    private let initialPage: Resource<Page>
    
    private var currentPage: Resource<Page>
    
    private(set) var pages: [Page] = []
    
    private(set) var pageItems: [Page.Item] = []
    
    private let constructPageResource: PageResourceConstructor
    
    init(initalPage: Resource<Page>, resourceConstructor: PageResourceConstructor?) {
        self.initialPage = initalPage
        self.currentPage = initalPage
        
        if let constructor = resourceConstructor {
            self.constructPageResource = constructor
        } else {
            self.constructPageResource = { latestResource, latestPage in
                return latestResource
            }
        }
    }

}

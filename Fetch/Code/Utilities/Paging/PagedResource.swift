//
//  PagedResource.swift
//  Fetch
//
//  Created by Oliver Krakora on 12.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

public enum PagingError: Error {
    case pagingInProgress
    case pagingReachedEnd
    case fetchError(FetchError)
}

/// The `PagedResource` is a complementary class that uses `Resource` to perform paging.
///
/// The PagedResource has two generic types:
///
/// **Page**: Is a custom type that must conform to the `PageProtocol` and represents a single page.
///
/// **MappedPageItem:** This type defines the type to which a `Page.Item` will be mapped when a page is loaded.
///
/// If you don't want to use the MappedPageItem you can make use of the type `SingleTypedPagedResource`.
public class PagedResource<Page: PageProtocol, MappedPageItem> {
    
    public typealias PageResourceConstructor = ((Resource<Page>, Page) -> Resource<Page>)
    
    public typealias ItemMappingClosure = ((Page.Item) -> MappedPageItem)
    
    public typealias PageResultClosure = ((Result<Page, PagingError>) -> Void)
    
    private let initialResource: Resource<Page>
    
    private var currentResource: Resource<Page>
    
    public var hasMorePages: Bool {
        return pages.last?.hasNext ?? true
    }
    
    public private(set) var pages: [Page] = []
    
    public private(set) var mappedItems: [MappedPageItem] = []
    
    #warning("Better naming for RequestToken")
    private var currentPageRequestToken: RequestToken?
    
    public let constructPageResource: PageResourceConstructor
    
    public let mapPageItemClosure: ItemMappingClosure
    
    /// - Parameter initialPage: The initial page where the paging begins
    /// - Parameter mappingClosure: The closure that will be called to map a `Page.Item` to `MappedPageItem`
    /// - Parameter resourceConstructor: A closure which provides the next page for a given Resource
    public init(initialPage: Resource<Page>, mappingClosure: @escaping ItemMappingClosure, resourceConstructor: @escaping PageResourceConstructor) {
        self.initialResource = initialPage
        self.currentResource = initialPage
        self.mapPageItemClosure = mappingClosure
        self.constructPageResource = resourceConstructor
    }
    
    /// Loads the next page
    /// - Parameter reset: When true all loaded pages will be removed and the initialPage will be loaded
    /// - Parameter callback: The closure that will be called with a `Result`
    #warning("Consider caching -> array of arrays in mappedItems")
    @discardableResult
    public func loadNext(reset: Bool = false, _ callback: @escaping PageResultClosure) -> RequestToken? {
        if reset {
            self.reset()
        }
        
        guard currentPageRequestToken == nil || currentPageRequestToken!.isCancelled else {
            callback(.failure(.pagingInProgress))
            return nil
        }
        
        guard hasMorePages else {
            callback(.failure(.pagingReachedEnd))
            return nil
        }
        
        currentPageRequestToken = currentResource.request(completion: { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let value):
                let page = value.model
                let mappedItems = page.items.map { self.mapPageItemClosure($0) }
                self.pages.append(page)
                self.mappedItems.append(contentsOf: mappedItems)
                self.currentResource = self.constructPageResource(self.currentResource, page)
                callback(.success(page))
            case .failure(let error):
                print(error)
                callback(.failure(.fetchError(error)))
            }
            
            self.currentPageRequestToken = nil
        })
        return currentPageRequestToken
    }
    
    /// Cancels the current request, removes all loaded pages and resets the currentPage to the initialPage.
    public func reset() {
        currentPageRequestToken?.cancel()
        currentPageRequestToken = nil
        currentResource = initialResource
        pages.removeAll()
        mappedItems.removeAll()
    }
}

public typealias SingleTypedPagedResource<Page: PageProtocol> = PagedResource<Page, Page.Item>

extension PagedResource where MappedPageItem == Page.Item {
    /// - Parameter initialPage: The initial page where the paging begins
    /// - Parameter resourceConstructor: A closure which provides the next page for a given Resource
    public convenience init(initialPage: Resource<Page>, resourceConstructor: @escaping PageResourceConstructor) {
        self.init(initialPage: initialPage, mappingClosure: { $0 }, resourceConstructor: resourceConstructor)
    }
}

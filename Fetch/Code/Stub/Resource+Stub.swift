//
//  Resource+Stub.swift
//  Fetch
//
//  Created by Oliver Krakora on 03.02.21.
//  Copyright © 2021 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

public extension Resource {
    func stubbed(withStub stub: Stub) -> Resource {
        return Resource(apiClient: apiClient,
                        headers: headers,
                        method: method,
                        baseURL: baseURL,
                        path: path,
                        urlParameters: urlParameters,
                        urlEncoding: urlEncoding,
                        body: body,
                        rootKeys: rootKeys,
                        cacheKey: cacheKey,
                        cachePolicy: cachePolicy,
                        cacheGroup: cacheGroup,
                        cacheExpiration: cacheExpiration,
                        multipartFormData: multipartFormData,
                        customValidation: customValidation,
                        shouldStub: shouldStub,
                        stub: stub,
                        decode: decode,
                        encode: encode)
    }
}

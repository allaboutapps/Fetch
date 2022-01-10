//
//  HTTPContentType.swift
//  Fetch
//
//  Created by Michael Heinzl on 04.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

/// The enum represents common HTTP content types
public enum HTTPContentType: CustomStringConvertible {
    case json
    case xml
    case yaml
    case imageJpeg
    case imagePng
    case custom(value: String)
    
    public var description: String {
        switch self {
        case .json:
            return "application/json"
        case .xml:
            return "application/xml"
        case .yaml:
            return "text/yaml"
        case .imageJpeg:
            return "image/jpeg"
        case .imagePng:
            return "image/png"
        case .custom(let value):
            return value
        }
    }
}

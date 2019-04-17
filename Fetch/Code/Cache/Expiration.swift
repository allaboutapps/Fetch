//
//  Expiration.swift
//  Fetch
//
//  Created by Matthias Buchetics on 15.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

public enum Expiration {
    
    case never
    case seconds(TimeInterval)
    case date(Date)
    
    public var date: Date {
        switch self {
        case .never:
            return Date.distantFuture
        case .seconds(let seconds):
            return Date().addingTimeInterval(seconds)
        case .date(let date):
            return date
        }
    }
    
    public var isExpired: Bool {
        return date.timeIntervalSinceNow < 0
    }
}

//
//  Decoder+Keys.swift
//  Fetch
//
//  Created by Michael Heinzl on 04.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

extension JSONDecoder: ResourceRootKeyDecoderProtocol {
    
    /// Returns a value of the type you specify, decoded from a JSON object using a list of keys
    /// to remove wrapped container objects. The last key contains the actual object.
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode.
    ///   - data: The data to decode from.
    ///   - key: The keys of the container objects.
    /// - Returns: The decoded value of the requested type.
    /// - Throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not valid JSON.
    /// - throws: An error if any value throws an error during decoding.
    public func decode<T: Decodable>(_ type: T.Type, from data: Data, keyedBy key: [String]) throws -> T {
        userInfo[.jsonDecoderRootKeyArrayName] = key
        let root = try decode(Envelop<T>.self, from: data)
        userInfo[.jsonDecoderRootKeyArrayName] = nil
        return root.value
    }
}

extension CodingUserInfoKey {
    static let jsonDecoderRootKeyArrayName = CodingUserInfoKey(rawValue: "rootKeyArray")!
}

struct Envelop<T>: Decodable where T: Decodable {
    
    /// Wrapper to use arbitrary String/Int as CodingKey
    private struct CodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        init?(intValue: Int) {
            self.intValue = intValue
            stringValue = "\(intValue)"
        }
    }
    
    let value: T
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Check if userInfo was properly set and check if rootKeys contain elements
        guard let rootKeys = decoder.userInfo[.jsonDecoderRootKeyArrayName] as? [String], rootKeys.count >= 1 else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: [],
                debugDescription: "No root keys found at \(CodingUserInfoKey.jsonDecoderRootKeyArrayName)"))
        }
        
        // Map rootKeys to CodingKeys
        let codingKeys = rootKeys.compactMap { CodingKeys(stringValue: $0) }
        let valueKey = codingKeys.last!
        
        // Unpack the nested containers until the last one
        let valueContainer = try codingKeys.dropLast().reduce(container) { (currentContainer, key) in
            return try currentContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: key)
        }
        // Decode the actual value from the last container
        value = try valueContainer.decode(T.self, forKey: valueKey)
    }
    
}

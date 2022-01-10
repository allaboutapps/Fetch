//
//  Crypto.swift
//  Fetch
//
//  Created by Matthias Buchetics on 03.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import CommonCrypto

struct Crypto {
    
    static func md5(_ data: Data) -> Data {
        var md5 = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        md5.withUnsafeMutableBytes { md5Buffer in
            data.withUnsafeBytes { buffer in
                _ = CC_MD5(buffer.baseAddress!, CC_LONG(buffer.count), md5Buffer.bindMemory(to: UInt8.self).baseAddress)
            }
        }
        
        return md5
    }
    
    static func sha1(_ data: Data) -> Data {
        var sha1 = Data(count: Int(CC_SHA1_DIGEST_LENGTH))
        
        sha1.withUnsafeMutableBytes { sha1Buffer in
            data.withUnsafeBytes { buffer in
                _ = CC_SHA1(buffer.baseAddress!, CC_LONG(buffer.count), sha1Buffer.bindMemory(to: UInt8.self).baseAddress)
            }
        }
        
        return sha1
    }
}

extension String {
    
    var md5: String? {
        guard let data = self.data(using: String.Encoding.utf8) else { return nil }
        return Crypto.md5(data).map { String(format: "%02x", $0) }.joined()
    }
    
    var sha1: String? {
        guard let data = self.data(using: String.Encoding.utf8) else { return nil }
        return Crypto.sha1(data).map { String(format: "%02x", $0) }.joined()
    }
}

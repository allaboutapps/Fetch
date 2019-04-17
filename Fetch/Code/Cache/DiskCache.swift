//
//  DiskCache.swift
//  Fetch
//
//  Created by Matthias Buchetics on 15.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation

public enum DiskCacheError: Error {
    case createFileFailed
    case missingModificationDate
    case fileEnumerationFailed
}

public class DiskCache: Cache {
    
    public enum Directory {
        case caches
        case document
        case url(URL)
    }
    
    struct File {
        let url: URL
        let resourceValues: URLResourceValues
    }

    public let url: URL
    
    private let maxSize: Int // in bytes
    private let defaultExpiration: Expiration
    private let returnIfExpired: Bool
    
    let fileManager = FileManager.default
    let jsonDecoder: ResourceDecoderProtocol
    let jsonEncoder: ResourceEncoderProtocol
    
    public init(name: String = "at.allaboutapps.DiskCache",
                directory: Directory = .caches,
                maxSize: Int = 0,
                jsonDecoder: ResourceDecoderProtocol = JSONDecoder(),
                jsonEncoder: ResourceEncoderProtocol = JSONEncoder(),
                defaultExpiration: Expiration = .never,
                returnIfExpired: Bool = true) throws {
        let directoryUrl: URL
        
        switch directory {
        case .caches:
            directoryUrl = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        case .document:
            directoryUrl = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        case .url(let customURL):
            directoryUrl = customURL
        }
        
        self.url = directoryUrl.appendingPathComponent(name, isDirectory: true)
        self.maxSize = maxSize
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
        self.defaultExpiration = defaultExpiration
        self.returnIfExpired = returnIfExpired
        
        try createDirectory(at: url)
    }
    
    func createDirectory(at url: URL) throws {
        guard !fileManager.fileExists(atPath: url.path) else {
            return
        }
        
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
    
    func directory(for resource: CacheableResource) -> URL {
        var resourceURL = url
        
        if let group = resource.cacheGroup {
            resourceURL.appendPathComponent(group, isDirectory: true)
        }
        
        return resourceURL
    }
    
    func path(for resource: CacheableResource) -> String {
        var resourceURL = directory(for: resource)
        resourceURL.appendPathComponent(resource.cacheKey)
        resourceURL.appendPathExtension("json")
        return resourceURL.path
    }
    
    private func allFiles() throws -> [File] {
        let resourceKeys: [URLResourceKey] = [
            .isDirectoryKey,
            .contentModificationDateKey,
            .fileSizeKey
        ]
        
        let fileEnumerator = fileManager.enumerator(at: self.url, includingPropertiesForKeys: resourceKeys)
        
        guard let files = fileEnumerator?.allObjects as? [URL] else {
            throw DiskCacheError.fileEnumerationFailed
        }
        
        var result = [File]()
        
        for url in files {
            guard let resourceValues = try? url.resourceValues(forKeys: Set(resourceKeys)), resourceValues.isDirectory == false else {
                continue
            }
            
            result.append(File(url: url, resourceValues: resourceValues))
        }
        
        return result
    }
    
    // MARK: Cache
    
    public func set<T>(_ data: T, for resource: CacheableResource) throws where T: Cacheable {
        let expiration = resource.cacheExpiration ?? defaultExpiration
        try set(data, expirationDate: expiration.date, for: resource)
    }
    
    public func set<T: Cacheable>(_ data: T, expirationDate: Date, for resource: CacheableResource) throws {
        let encodedData = try jsonEncoder.encode(data)
        let directoryURL = directory(for: resource)
        let filePath = path(for: resource)
        
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        
        if fileManager.createFile(atPath: filePath, contents: encodedData, attributes: [.modificationDate: expirationDate]) == false {
            throw DiskCacheError.createFileFailed
        }
        
        print("[DiskCache] set \(resource.cacheKey)")
    }
    
    public func get<T>(for resource: CacheableResource) throws -> CacheEntry<T>? where T: Cacheable {
        let filePath = path(for: resource)
        let attributes = try fileManager.attributesOfItem(atPath: filePath)
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        let decodedData = try jsonDecoder.decode(T.self, from: data)
        
        guard let date = attributes[.modificationDate] as? Date else {
            throw DiskCacheError.missingModificationDate
        }
        
        guard returnIfExpired || date.timeIntervalSinceNow >= 0 else {
            print("[MemoryCache] get \(resource.cacheKey): is expired")
            try? remove(for: resource)
            return nil
        }
        
        print("[DiskCache] get \(resource.cacheKey): found")
        return CacheEntry(data: decodedData, expirationDate: date)
    }
    
    public func remove(for resource: CacheableResource) throws {
        print("[DiskCache] remove \(resource.cacheKey)")
        
        let filePath = path(for: resource)
        try fileManager.removeItem(atPath: filePath)
    }
    
    public func remove(group: String) throws {
        print("[DiskCache] remove group \(group)")
        
        let path = url.appendingPathComponent(group).path
        try fileManager.removeItem(atPath: path)
    }
    
    public func removeExpired() throws {
        try removeExpired(olderThan: Date())
    }
    
    public func removeExpired(olderThan date: Date) throws {
        print("[DiskCache] remove expired older than \(date)")
        
        var filesToDelete = [URL]()
        
        for file in try allFiles() {
            if let expirationDate = file.resourceValues.contentModificationDate, expirationDate < date {
                filesToDelete.append(file.url)
                continue
            }
        }
        
        for url in filesToDelete {
            try fileManager.removeItem(at: url)
        }
    }
    
    public func removeAll() throws {
        print("[DiskCache] remove all")
        try fileManager.removeItem(atPath: url.path)
        try createDirectory(at: url)
    }
    
    // MARK: Cleanup
    
    public func computeTotalSize() throws -> Int {
        var size: Int = 0
        let contents = try fileManager.contentsOfDirectory(atPath: url.path)
        
        for pathComponent in contents {
            let filePath = url.appendingPathComponent(pathComponent).path
            let attributes = try fileManager.attributesOfItem(atPath: filePath)
            if let fileSize = attributes[.size] as? Int {
                size += fileSize
            }
        }
        
        return size
    }
    
    public func cleanup() throws {
        guard maxSize > 0 else { return }
        
        var totalSize = try computeTotalSize()
        let targetSize = maxSize / 2
        
        if totalSize < maxSize {
            return
        }
        
        let sortedFiles = try allFiles().sorted(by: { (f1, f2) -> Bool in
            if let date1 = f1.resourceValues.contentModificationDate, let date2 = f2.resourceValues.contentModificationDate {
                return date1 > date2
            } else {
                return false
            }
        })
        
        var filesToDelete = [URL]()
        
        for file in sortedFiles {
            filesToDelete.append(file.url)
            
            if let fileSize = file.resourceValues.fileSize {
                totalSize -= Int(fileSize)
            }
            
            if totalSize < targetSize {
                break
            }
        }
        
        for url in filesToDelete {
            try fileManager.removeItem(at: url)
        }
    }
}

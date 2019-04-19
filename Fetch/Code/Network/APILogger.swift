//
//  APILogger.swift
//  Fetch
//
//  Created by Michael Heinzl on 02.04.19.
//  Copyright © 2019 aaa - all about apps GmbH. All rights reserved.
//

import Foundation
import Alamofire

/// The `APILogger` is used as an `EventMonitor` to log network requests and responds
public class APILogger: EventMonitor {
    
    public static let apiLogDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    public typealias CustomLogClosure = ((_ timeStamp: Date, _ message: String, _ requestId: UUID) -> Void)
    
    public typealias CustomOutputClosure = ((String) -> Void)
    
    /// If `customLogClosure` is set every log entry is passed into `customLogClosure`
    public var customLogClosure: CustomLogClosure?
    
    public var customOutputClosure: CustomOutputClosure?
    
    /// Enables verbose logging if `true`
    public let verbose: Bool
    
    /// Initializes a new APILogger
    ///
    /// - Parameter verbose: Enables verbose logging if `true`
    public init(verbose: Bool) {
        self.verbose = verbose
    }
    
    // MARK: - Event Monitor
    
    public func requestDidResume(_ request: Request) {
        guard let urlRequest = request.request else {
            printMessage("🔸 No Request", with: request.id)
            return
        }
        
        var output = [String]()
        let isStubbed = urlRequest.headers.dictionary.keys.contains(StubbedURLProtocol.stubIdHeader)
        output.append("↗️\(isStubbed ? " [STUB]" : "") \(urlRequest.httpMethod ?? "") - \(urlRequest.url?.absoluteString ?? "")")
        
        let spacing = "         "
        if let headers = urlRequest.allHTTPHeaderFields, verbose {
            output.append("\(spacing)Headers:")
            let formattedHeaders = headers
                .map { "\(spacing)   \($0.0): \($0.1)" }
                .joined(separator: "\n")
            output.append(formattedHeaders)
        }
        
        if let body = prettyJSON(data: urlRequest.httpBody), verbose {
            output.append("\(spacing)Request Body:")
            output.append(body)
        }
        
        printMessage(output.joined(separator: "\n"), with: request.id)
    }
    
    public func request(_ request: Alamofire.Request, didCompleteTask task: URLSessionTask, with error: Error?) {
        guard let response = task.response as? HTTPURLResponse else {
            printMessage("🔸 No HTTPURLResponse", with: request.id)
            return
        }

        guard let urlRequest = request.request else {
            printMessage("🔸 Response has no request", with: request.id)
            return
        }

        var output = [String]()
        
        let range = 200...399
        let icon = range.contains(response.statusCode) ? "✅" : "❌"
        let isStubbed = urlRequest.headers.dictionary.keys.contains(StubbedURLProtocol.stubIdHeader)

        output.append("\(icon)\(isStubbed ? " [STUB]" : "") \(response.statusCode) \(urlRequest.httpMethod ?? "") - \(urlRequest.url?.absoluteString ?? "")")

        if let data = (request as? DataRequest)?.data,
            let body = prettyJSON(data: data) ?? String(data: data, encoding: .utf8), verbose {
            output.append(body)
        }

        if let error = error {
            output.append("💢 Error: \(error)")
        }
        
        printMessage(output.joined(separator: "\n"), with: request.id)
    }
    
    // MARK: - Helper
    
    private func prettyJSON(data: Data?) -> String? {
        if let data = data,
            let json = try? JSONSerialization.jsonObject(with: data, options: []),
            let prettyJson = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
            let string = NSString(data: prettyJson, encoding: String.Encoding.utf8.rawValue) {
            return string as String
        }

        return nil
    }
    
    private func printMessage(_ message: String, with requestId: UUID) {
        let now = Date()

        if let customLogClosure = customLogClosure {
            customLogClosure(now, message, requestId)
        } else {
            var output = "[\(APILogger.apiLogDateFormatter.string(from: now))] "
            if verbose {
                output += "Request ID: \(requestId.uuidString)\n"
            }
            output += message
            if let out = customOutputClosure {
                out(output)
            } else {
                print(output)
            }
        }
    }
}

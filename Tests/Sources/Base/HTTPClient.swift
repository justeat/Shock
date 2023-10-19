//  HTTPClient.swift

import Foundation
import XCTest

private let session = URLSession.shared

typealias HTTPClientResult = (_ code: Int, _ response: String, _ headers: [String: String], _ error: Error?) -> Void

class HTTPClient {
    
    static func get(url: String, headers: [String: String] = [:], timeout: Int? = nil, completion: @escaping HTTPClientResult) {
        execute(url: url, method: "GET", headers: headers, timeout: timeout, completion: completion)
    }
    
    static func post(url: String, headers: [String: String] = [:], timeout: Int? = nil, completion: @escaping HTTPClientResult) {
        execute(url: url, method: "POST", headers: headers, timeout: timeout, completion: completion)
    }
    
    static func put(url: String, headers: [String: String] = [:], timeout: Int? = nil, completion: @escaping HTTPClientResult) {
        execute(url: url, method: "PUT", headers: headers, timeout: timeout, completion: completion)
    }
    
    static func delete(url: String, headers: [String: String] = [:], timeout: Int? = nil, completion: @escaping HTTPClientResult) {
        execute(url: url, method: "DELETE", headers: headers, timeout: timeout, completion: completion)
    }
    
    private static func execute(url: String, method: String = "GET", headers: [String: String] = [:], timeout: Int? = nil, completion: @escaping HTTPClientResult) {
        
        var request = URLRequest(url: URL(string: url)!)
        if let timeout = timeout {
            request.timeoutInterval = TimeInterval(timeout)
        }
        request.httpMethod = method
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(0, "", [:], error)
            } else {
                let response = response as! HTTPURLResponse
                completion(response.statusCode, String(data: data!, encoding: .utf8)!, response.allHeaderFields as! [String: String], error)
            }
        }
        task.resume()
    }
}

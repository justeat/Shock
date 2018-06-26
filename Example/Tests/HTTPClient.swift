//
//  HTTPClient.swift
//  Shock
//
//  Created by Jack Newcombe on 06/10/2017.
//

import Foundation
import XCTest

fileprivate let session = URLSession.shared

typealias HTTPClientResult = (_ code: Int, _ response: String) -> Void

class HTTPClient {

    static func get(url: String, headers: [String: String] = [:], completion: @escaping HTTPClientResult) {
        execute(url: url, method: "GET", headers: headers, completion: completion)
    }
    
    static func post(url: String, headers: [String: String] = [:], completion: @escaping HTTPClientResult) {
        execute(url: url, method: "POST", headers: headers, completion: completion)
    }

    static func put(url: String, headers: [String: String] = [:], completion: @escaping HTTPClientResult) {
        execute(url: url, method: "PUT", headers: headers, completion: completion)
    }

    static func delete(url: String, headers: [String: String] = [:], completion: @escaping HTTPClientResult) {
        execute(url: url, method: "DELETE", headers: headers, completion: completion)
    }

    private static func execute(url: String, method: String = "GET", headers: [String: String] = [:], completion: @escaping HTTPClientResult) {
		
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = method
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
		let task = session.dataTask(with: request) { data, response, error in
			let response = response as! HTTPURLResponse
			completion(response.statusCode, String(data: data!, encoding: .utf8)!)
		}
		task.resume()
	}

}

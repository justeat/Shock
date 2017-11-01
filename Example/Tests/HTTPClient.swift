//
//  HTTPClient.swift
//  Shock
//
//  Created by Jack Newcombe on 06/10/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import XCTest

fileprivate let session = URLSession.shared

typealias HTTPClientResult = (_ code: Int, _ response: String) -> Void

class HTTPClient {

    static func get(url: String, headers: [String: String] = [:], completion: @escaping HTTPClientResult) {
		
        var request = URLRequest(url: URL(string: url)!)
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
		let task = session.dataTask(with: request) { data, response, error in
			let response = response as! HTTPURLResponse
			completion(response.statusCode, String(data: data!, encoding: .utf8)!)
		}
		task.resume()
	}

}

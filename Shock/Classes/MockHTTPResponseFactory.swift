//
//  HTTPResponseFactory.swift
//  JustEat
//
//  Created by Jack Newcombe on 29/09/2017.
//  Copyright © 2017 JUST EAT. All rights reserved.
//

import Foundation
import Swifter
import GRMustache

fileprivate typealias Template = GRMustacheTemplate

class MockHTTPResponseFactory {
	
	let bundle: Bundle
	
	init(bundle: Bundle = Bundle.main) {
		self.bundle = bundle
	}
	
	func create(url: String, jsonFilename: String, method: String = "GET", code: Int = 200) -> HttpResponse {
		return HttpResponse.raw(code, url, nil) { writer in
			let responseBody = self.loadJson(named: jsonFilename)!
			try! writer.write(responseBody.data(using: String.Encoding.utf8)!)
		}
	}
	
	func create(url: String, templateFilename: String, data: [String: Any?] = [:], method: String = "GET", code: Int = 200) -> HttpResponse {
		
		return HttpResponse.raw(code, url, nil) { writer in
			
			let responseBody: String?
			let template = try! Template(fromResource: templateFilename, bundle: self.bundle)
			responseBody = try! template.renderObject(data)

			try! writer.write(responseBody!.data(using: String.Encoding.utf8)!)
		}
	}
	
	func create(url: String, destination: String) -> HttpResponse {
		return HttpResponse.movedPermanently(destination)
	}
	
	// MARK: Utilities
	
	func loadJson(named name: String) -> String? {
		
		let components = name.components(separatedBy: ".")
		let url: URL
		if components.count == 1 {
			url = bundle.url(forResource: components[0], withExtension: "json")!
		} else if components.count > 1 {
			var components = components
			let ext = components.removeLast()
			url = bundle.url(forResource: components.joined(separator: "."), withExtension: ext)!
		} else {
			url = URL(string: name)!
		}
		
		return try? String(contentsOf: url)
	}
	
}

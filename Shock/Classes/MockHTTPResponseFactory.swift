//
//  HTTPResponseFactory.swift
//  Shock
//
//  Created by Jack Newcombe on 27/06/2018.
//  Copyright © 2018 Just Eat. All rights reserved.
//

import Foundation
import Swifter
import GRMustache

fileprivate typealias Template = GRMustacheTemplate

class MockHTTPResponseFactory {
	
	private let bundle: Bundle
	
	init(bundle: Bundle = Bundle.main) {
		self.bundle = bundle
	}
	
	func makeResponse(urlPath: String, jsonFilename: String?, method: String = "GET", code: Int = 200) -> HttpResponse {
        return HttpResponse.raw(code, urlPath, nil) { writer in
            guard let jsonFilename = jsonFilename,let responseBody = self.loadJson(named: jsonFilename) else { return }
            try! writer.write(responseBody.data(using: String.Encoding.utf8)!)
		}
	}
	
	func makeResponse(urlPath: String, templateFilename: String?, data: [String: Any?]? = nil, method: String = "GET", code: Int = 200) -> HttpResponse {
		
		return HttpResponse.raw(code, urlPath, nil) { writer in
            guard let templateFilename = templateFilename, let data = data else { return }
            let template = try! Template(fromResource: templateFilename, bundle: self.bundle)
            let responseBody: String = try! template.renderObject(data)
            try! writer.write(responseBody.data(using: String.Encoding.utf8)!)
        }
	}
	
	func makeResponse(urlPath: String, destination: String) -> HttpResponse {
		return HttpResponse.movedPermanently(destination)
	}
	
	// MARK: Utilities
	
	private func loadJson(named name: String) -> String? {
		
		let components = name.components(separatedBy: ".")
		let url: URL
        
        switch components.count {
        case 0:
            url = URL(string: name)!
        case 1:
            url = bundle.url(forResource: components[0], withExtension: "json")!
        default:
            var components = components
            let ext = components.removeLast()
            url = bundle.url(forResource: components.joined(separator: "."), withExtension: ext)!
        }
        
		return try? String(contentsOf: url)
	}
	
}

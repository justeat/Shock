//
//  MockAPI.swift
//  JustEat
//
//  Created by Jack Newcombe on 31/10/2016.
//  Copyright © 2016 JUST EAT. All rights reserved.
//

// Force tries are bad in the app but in a test-case it's good to have a crash
// if server unavailable
// swiftlint:disable force_try

import UIKit
import Swifter

public class MockServer {

	let port: UInt16
	
	let server = HttpServer()
	
	let factory: MockHTTPResponseFactory
	
	public var priority: DispatchQoS.QoSClass = .default
	
	public init(port: UInt16 = 9000, bundle: Bundle = Bundle.main) {
		self.port = port
		self.factory = MockHTTPResponseFactory(bundle: bundle)
	}
	
	// MARK: Server managements
	
	public func start() {
		try! server.start(port, forceIPv4: true, priority: priority)
	}
	
	public func stop() {
		server.stop()
	}
	
	public var hostURL: String {
		return "http://localhost:\(port)"
	}
	
	// MARK: Mock setup
	
	public func setupRoute(route: MockHTTPRoute) {
		
		let response: HttpResponse?
		
		switch route {
		case .simple(let method, let url, let code, let jsonFilename),
		     .custom(let method, let url, _, _, let code, let jsonFilename):
			response = factory.create(url: url, jsonFilename: jsonFilename, method: method.rawValue, code: code)
			break
		case .template(let method, let url, let code, let jsonFileName, let data):
			response = factory.create(url: url, templateFilename: jsonFileName, data: data, method: method.rawValue, code: code)
			break
		case .redirect(let url, let destination):
			response = factory.create(url: url, destination: destination)
			break
		case .collection(let routes):
			routes.forEach { self.setupRoute(route: $0) }
			return
		}
		
		if let response = response, let url = route.url, let method = route.method {
			
			var router = method == .GET ? server.GET : server.POST
			
			router[url] = { request in
				assert(method == route.method)
                
                if let headers = route.headers {
                    let match = headers.map({ request.headers[$0.key.lowercased()] == $0.value }).reduce(true, { $0 && $1 })
                    if !match {
                        return .notFound
                    }
				}

				if let routeDict = route.query, let url = URL(string: url) {
                    let query = url.query ?? ""
					let dict = dictionary(from: query)
					if dict != routeDict  {
						return .notFound
					}
				}

				print("Executing request for route: \(request.method) \(request.path)")
				return response
			}
		}
	}
	
}

// MARK: Utils

fileprivate func dictionary(from query: String) -> [String: String] {
	let components = query.components(separatedBy: "&")
	var dict = [String: String]()
	components.forEach {
		let kvp = $0.components(separatedBy: "=")
		if kvp.count == 2 {
			dict[kvp[0]] = kvp[1]
		}
	}
	return dict
}

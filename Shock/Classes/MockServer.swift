//
//  MockAPI.swift
//  Shock
//
//  Created by Jack Newcombe on 27/06/2018.
//  Copyright © 2018 Just Eat. All rights reserved.
//

// Force tries are bad in the app but in a test-case it's good to have a crash
// if server unavailable
// swiftlint:disable force_try

import Foundation
import Swifter

public class MockServer {

	private let port: UInt16
	
	private let server = HttpServer()
	
	private let responseFactory: MockHTTPResponseFactory
	
	public init(port: UInt16 = 9000, bundle: Bundle = Bundle.main) {
		self.port = port
		self.responseFactory = MockHTTPResponseFactory(bundle: bundle)
	}
	
	// MARK: Server managements
	
	public func start(priority: DispatchQoS.QoSClass = .default) {
		try! server.start(port, forceIPv4: true, priority: priority)
	}
	
	public func stop() {
		server.stop()
	}
	
	public var hostURL: String {
		return "http://localhost:\(port)"
	}
	
	// MARK: Mock setup
	
	public func setup(route: MockHTTPRoute) {
		
		let response: HttpResponse
		
		switch route {
		case .simple(let method, let urlPath, let code, let jsonFilename),
		     .custom(let method, let urlPath, _, _, let code, let jsonFilename):
			response = responseFactory.makeResponse(urlPath: urlPath, jsonFilename: jsonFilename, method: method.rawValue, code: code)
			break
		case .template(let method, let urlPath, let code, let jsonFileName, let data):
			response = responseFactory.makeResponse(urlPath: urlPath, templateFilename: jsonFileName, data: data, method: method.rawValue, code: code)
			break
		case .redirect(let urlPath, let destination):
			response = responseFactory.makeResponse(urlPath: urlPath, destination: destination)
			break
		case .collection(let routes):
			routes.forEach { self.setup(route: $0) }
			return
		}
		
        if let urlPath = route.urlPath, let method = route.method {
			
			var router = httpServerMethod(for: method)
			
			router[urlPath] = { request in
				assert(method == route.method)
                
                if let headers = route.headers {
                    let match = headers.map({ request.headers[$0.key.lowercased()] == $0.value }).reduce(true, { $0 && $1 })
                    if !match {
                        return .notFound
                    }
				}

				if let routeDict = route.query {
                    if dictionary(from: request.queryParams) != routeDict {
                        return .notFound
                    }
				}

				print("Executing request for route: \(request.method) \(request.path)")
				return response
			}
		}
	}
    
    // MARK: Utils
    
    private func httpServerMethod(for method: MockHTTPMethod) -> HttpServer.MethodRoute {
        switch method {
        case .GET:      return server.GET
        case .POST:     return server.POST
        case .PUT:      return server.PUT
        case .DELETE:   return server.DELETE
        }
    }
	
}

// MARK: Utils

fileprivate func dictionary(from query: [(String, String)]) -> [String: String] {
    var dict = [String: String]()
    query.forEach { dict[$0.0] = $0.1 }
    return dict
}

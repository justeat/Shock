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
	
	public var isRunning: Bool {
		return server.operating
	}
	
	public var hostURL: String {
		return "http://localhost:\(port)"
	}
	
	// MARK: Mock setup
	
	public func setupRoute(route: MockHTTPRoute) {
		
		let response: HttpResponse?
		
		switch route {
		case .simple(let method, let url, let jsonFilename):
			response = factory.create(url: url, jsonFilename: jsonFilename, method: method.rawValue)
			break
		case .template(let method, let url, let jsonFileName, let data):
			response = factory.create(url: url, templateFilename: jsonFileName, data: data, method: method.rawValue)
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
				print("Executing request for route: \(request.method) \(request.path)")
				return response
			}
		}
	}
	
}

//
//  MyRoutes.swift
//  Shock
//
//  Created by Jack Newcombe on 06/10/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import Shock

class MyRoutes {
	
	private let routes: [MockHTTPRoute]
	
	private let server = MockServer(port: 9091, bundle: Bundle.main)
	
	init() {
		
		routes = [
			.simple(method: .GET, url: "/helloworld", filename: "helloworld.txt")
		]
		
		server.setupRoute(route: .collection(routes: routes))
		server.priority = DispatchQoS.QoSClass.background
		server.start()
	}
	
	func nameForRoute(index: Int) -> String {
		if let url = routes[index].url, let method = routes[index].method {
			return "\(method) \(url)"
		}
		return ""
	}
	
	var count: Int {
		return routes.count
	}
	
	func makeRequest(index: Int, completion: @escaping (HTTPURLResponse, Data) -> ()) {
		if let routeURL = routes[index].url, let url = URL(string: "\(server.hostURL)\(routeURL)") {
			print("Requesting \(url.absoluteString)")
			let task = URLSession.shared.dataTask(with: url) { data, response, error in
				completion(response as! HTTPURLResponse, data ?? Data())
			}
			task.resume()
		}
	}
}

//
//  MyRoutes.swift
//  Shock
//
//  Created by Jack Newcombe on 27/06/2018.
//  Copyright © 2018 Just Eat. All rights reserved.
//

import Foundation
import Shock

class MyRoutes {
	
	private let routes: [MockHTTPRoute]
	
	private let server = MockServer(port: 9091, bundle: Bundle.main)
	
	init() {
		
        // Add your own routes here to test them in the example app
		routes = [
            .simple(
                method: .get,
                urlPath: "/simple",
                code: 200,
                filename: "simple-route"
            ),
            .custom(
                method: .post,
                urlPath: "/custom",
                query: ["item": "value"],
                requestHeaders: ["X-Custom-Header": "custom-header-value"],
                responseHeaders: [:],
                code: 200,
                filename: "custom-route.json"
            ),
            .redirect(
                urlPath: "/redirect-to-simple",
                destination: "/simple"
            ),
            .template(
                method: .post,
                urlPath: "/template",
                code: 200,
                filename: "template-route.json",
                templateInfo: ["templateKey": "A templated value"]
            ),
            .timeout(method: .get,
                     urlPath: "/timeout")
		]
		
		server.setup(route: .collection(routes: routes))
		server.start(priority: DispatchQoS.QoSClass.background)
	}
	
	func nameOfRoute(at index: Int) -> String {
        if let urlPath = routes[index].urlPath, let method = routes[index].method {
            return "\(method) \(urlPath)"
		}
		return ""
	}
	
	var count: Int {
		return routes.count
	}
	
	func performRequest(index: Int, completion: @escaping (HTTPURLResponse, Data, Error?) -> ()) {

        let route = routes[index]
        
        guard let urlPath = route.urlPath, var urlComponents = URLComponents(string: "\(server.hostURL)\(urlPath)") else {
            print("ERROR: failed to derive URL from mock route")
            return
        }
        
        if let query = route.query {
            urlComponents.queryItems = query.keys.map({ URLQueryItem(name: $0, value: query[$0]) })
        }
        
        guard let url = urlComponents.url else {
            print("ERROR: Couldn't construct URL from components - \(urlComponents)")
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.allHTTPHeaderFields = route.requestHeaders
        urlRequest.httpMethod = route.method?.rawValue ?? "GET"
        
        print("Requesting \(url.absoluteString)")

        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(HTTPURLResponse(), Data(), error)
            } else {
                completion(response as! HTTPURLResponse, data ?? Data(), error)
            }
        }
        task.resume()
	}
}

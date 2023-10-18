//  MockRoutesManager.swift

import Foundation
import Shock

class MockRoutesManager {
    
    private var routesDictionary: [Int: MockHTTPRoute] = [:]
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return dateFormatter
    }()
    
    func routeExists(response: URLResponse) -> Bool {
        guard let url = response.url else {
            return false
        }
        let urlPath = url.path
        return routesDictionary.contains { route in
            guard route.value.urlPath == urlPath else {
                return false
            }
            return url.queryEquals(parameters: route.value.query)
        }
    }
    
    func fileName(url: URL, method: String, index: Int) -> String {
        let timestamp = dateFormatter.string(from: Date())
        let prefix = String(format: "%03d", index)
        let path = url.pathComponents.dropFirst().joined(separator: "_")
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        let queryItems = components?.queryItems?.compactMap { item -> String? in
            guard let value = item.value else { return nil }
            return "\(item.name)__\(value)"
        }
        if let query = queryItems?.joined(separator: "--") {
            return "\(timestamp)_\(prefix)_\(method)_\(path)--\(query)"
        } else {
            return "\(timestamp)_\(prefix)_\(method)_\(path)"
        }
    }
    
    func addMockHttpRoute(request: URLRequest, response: URLResponse, at index: Int) {
        guard let url = response.url,
              let methodValue = request.httpMethod,
              let statusCode = (response as? HTTPURLResponse)?.statusCode,
              let method = MockHTTPMethod(rawValue: methodValue) else {
            return
        }
        let name = fileName(url: url, method: method.rawValue, index: index)
        let filename = "\(name).json"
        let urlPath = url.path
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        
        // NOTE: We assume all the query items key are different
        if let queryItems = components?.queryItems {
            var query: [String: String] = [:]
            for item in queryItems {
                if let value = item.value {
                    query[item.name] = value
                }
            }
            let route = MockHTTPRoute.custom(
                method: method,
                urlPath: urlPath,
                query: query,
                requestHeaders: [:],
                responseHeaders: [:],
                code: statusCode,
                filename: filename
            )
            routesDictionary[index] = route
        } else {
            let route = MockHTTPRoute.simple(
                method: method,
                urlPath: urlPath,
                code: statusCode,
                filename: filename)
            routesDictionary[index] = route
        }
    }
    
    func collectionRoutes() -> MockHTTPRoute {
        var routes: [MockHTTPRoute] = []
        for key in routesDictionary.keys.sorted(by: { $0 < $1 }) {
            guard let value = routesDictionary[key] else {
                continue
            }
            routes.append(value)
        }
        return MockHTTPRoute.collection(routes: routes)
    }
}

private extension URL {
    func queryEquals(parameters: [String: String]?) -> Bool {
        let components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        guard let parameters = parameters else {
            return components?.queryItems == nil
        }
        guard let queryItems = components?.queryItems else {
            return parameters.isEmpty
        }
        for (key, value) in parameters {
            guard queryItems.contains(where: { $0.name == key && $0.value == value}) else {
                return false
            }
        }
        return true
    }
}

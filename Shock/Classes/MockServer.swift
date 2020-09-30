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

public class MockServer {
    
    /// The range in which to find a free port on which to launch the server
    private let portRange: ClosedRange<Int>
    
    private var server = NIOHttpServer()
    
//    private let portProvider = PortProvider()
    
    private let responseFactory: MockHTTPResponseFactory
    
    public var onRequestReceived: ((MockHTTPRoute, CacheableRequest) -> Void)?
    
    public var selectedPort = 0
    
    public var loggingClosure: ((String?) -> Void)?
    
    public convenience init(port: Int = 9000, bundle: Bundle = Bundle.main) {
        self.init(portRange: port...port, bundle: bundle)
    }
    
    public init(portRange: ClosedRange<Int>, bundle: Bundle = Bundle.main) {
        self.portRange = portRange
        self.responseFactory = MockHTTPResponseFactory(bundle: bundle)
    }
    
    // MARK: Server managements
    
    public func start(priority: DispatchQoS.QoSClass = .default) {
        for i in portRange {
            let proposedPort = i
            do {
                try server.start(proposedPort, forceIPv4: true, priority: priority)
                selectedPort = proposedPort
                loggingClosure?("SUCCESS: Opened server on port: \(i)")
                return
            } catch _ {
                loggingClosure?("NOTE: Failed to open server on port: \(i), \(portRange.upperBound - i) remaining")
                continue
            }
        }
        loggingClosure?("""
ERROR: Failed to open server on port in range \(portRange.upperBound)...\(portRange.lowerBound).
Run `netstat -anptcp | grep LISTEN` to check which ports are in use.")
""")
    }
    
    public func stop() {
        server.stop()
        loggingClosure?("SUCCESS: Closed server on port: \(selectedPort)")
    }
    
    public func forceAllCallsToBeMocked() {
        server.notFoundHandler = { request in
            assertionFailure("Not handled: \(request.method) \(request.path)")
            return .internalServerError
        }
    }
    
    public var hostURL: String {
        return "http://localhost:\(selectedPort)"
    }
    
    // MARK: Mock setup
    
    public func setup(route: MockHTTPRoute) {
        
        let response: HttpResponse
        
        switch route {
        case .simple(let method, let urlPath, let code, let jsonFilename):
            response = responseFactory.makeResponse(urlPath: urlPath,
                                                    jsonFilename: jsonFilename,
                                                    method: method.rawValue,
                                                    code: code)
        case .custom(let method, let urlPath, _, _, let responseHeaders, let code, let jsonFilename):
            response = responseFactory.makeResponse(urlPath: urlPath,
                                                    jsonFilename: jsonFilename,
                                                    method: method.rawValue,
                                                    code: code,
                                                    headers: responseHeaders)
        case .template(let method, let urlPath, let code, let jsonFileName, let data):
            response = responseFactory.makeResponse(urlPath: urlPath,
                                                    templateFilename: jsonFileName,
                                                    data: data,
                                                    method: method.rawValue,
                                                    code: code)
        case .redirect(let urlPath, let destination):
            response = responseFactory.makeResponse(urlPath: urlPath, destination: destination)
        case .collection(let routes):
            routes.forEach { self.setup(route: $0) }
            return
        case .timeout(let method, let urlPath, let timeoutInSeconds):
            response = responseFactory.makeResponse(urlPath: urlPath, method: method.rawValue, timeout: timeoutInSeconds)
        }
        
        if let urlPath = route.urlPath, let method = route.method {
            
            var router = httpServerMethod(for: method)
            
            router[urlPath] = { request in
                assert(method == route.method)
                
                // API Request data can be accessible by the testcase
                self.onRequestReceived?(route, request)
                
                if let headers = route.requestHeaders {
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
                
                self.loggingClosure?("Executing request for route: \(request.method) \(request.path)")
                return response
            }
        }
    }
    
    // MARK: Utils
    
    private func httpServerMethod(for method: MockHTTPMethod) -> MethodRoute {
        switch method {
        case .get:      return server.GET
        case .head:     return server.HEAD
        case .post:     return server.POST
        case .put:      return server.PUT
        case .patch:    return server.PATCH
        case .delete:   return server.DELETE
        }
    }
    
}

// MARK: Utils

fileprivate func dictionary(from query: [(String, String)]) -> [String: String] {
    var dict = [String: String]()
    query.forEach { dict[$0.0] = $0.1 }
    return dict
}

public protocol CacheableRequest {
    var path: String { get }
    var queryParams: [(String, String)] { get }
    var method: String { get }
    var headers: [String: String] { get }
    var body: [UInt8] { get }
    var address: String? { get }
    var params: [String: String] { get }
}

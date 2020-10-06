//
//  MockNIOHTTPServer.swift
//  Shock
//
//  Created by Antonio Strijdom on 30/09/2020.
//

import Foundation
import NIO
import NIOHTTP1

/// SwiftNIO implementation of mock HTTP server
class MockNIOHttpServer: MockNIOBaseServer, MockHttpServer {
    
    private let router = MockNIOHTTPRouter()
    private let middlewareService = MiddlewareService()

    var notFoundHandler: ((MockHttpRequest) -> MockHttpResponse)?
    var methodRoutes: [MockHTTPMethod: MockNIOHTTPMethodRoute] = [:]
    
    
    override init() {
        methodRoutes[.delete] = MockNIOHTTPMethodRoute(method: "DELETE", router: router)
        methodRoutes[.patch] = MockNIOHTTPMethodRoute(method: "PATCH", router: router)
        methodRoutes[.head] = MockNIOHTTPMethodRoute(method: "HEAD", router: router)
        methodRoutes[.post] = MockNIOHTTPMethodRoute(method: "POST", router: router)
        methodRoutes[.get] = MockNIOHTTPMethodRoute(method: "GET", router: router)
        methodRoutes[.put] = MockNIOHTTPMethodRoute(method: "PUT", router: router)
        super.init()
    }
    
    func start(_ port: Int, forceIPv4: Bool, priority: DispatchQoS.QoSClass) throws -> Void {
        try start(port) { (channel) -> EventLoopFuture<Void> in
            channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
                channel.pipeline.addHandler(MockNIOHTTPHandler(router: self.router,
                                                               middlewareService: self.middlewareService))
            }
        }
    }
    
    func add(middleware: Middleware) {
        middlewareService.add(middleware: middleware)
    }
    
    func has<T>(middlewareOfType type: T.Type) -> Bool where T: Middleware {
        return middlewareService.middleware.contains { $0 is T }
    }
}

struct MockNIOHTTPMethodRoute: MockMethodRoute {
    let method: String
    let router: MockHttpRouter
}

class MockNIOHTTPRouter: MockHttpRouter {
    typealias PathHandlerMapping = [String: MockMethodRoute.HandlerClosure]
    private var routes = [String: PathHandlerMapping]()
    
    func handlerForMethod(_ method: String, path: String) -> MockMethodRoute.HandlerClosure? {
        let methodRoutes = routes[method] ?? PathHandlerMapping()
        for (candidate, handler) in methodRoutes {
            if candidate.pathMatchesStrippingVariables(path) {
                return handler
            }
        }
        return nil
    }
    
    func register(_ method: String, path: String, handler: MockMethodRoute.HandlerClosure?) {
        var methodRoutes = routes[method] ?? PathHandlerMapping()
        methodRoutes[path] = handler
        routes[method] = methodRoutes
    }
}

class MockNIOHTTPResponseBodyWriter: MockHttpResponseBodyWriter {
    var buffer = ByteBuffer(bytes: [])
    var contentLength: Int {
        buffer.readableBytes
    }
    func write(_ data: Data) throws {
        buffer = ByteBuffer(bytes: data)
    }
}

struct MockNIOHTTPRequest: MockHttpRequest {
    var path: String
    var queryParams: [(String, String)]
    var method: String
    var headers: [String : String]
    var body: [UInt8]
    var address: String?
    var params: [String : String]
}

extension String {
    func pathMatchesStrippingVariables(_ other: String) -> Bool {
        let parts = self.split(separator: "/")
        let otherParts = other.split(separator: "/")
        guard parts.count == otherParts.count else { return false }
        var match = true
        for (index, part) in parts.enumerated() {
            if part.hasPrefix(":") {
                continue
            }
            let otherPart = otherParts[index]
            if otherPart.hasPrefix(":") {
                continue
            }
            match = part == otherPart
            if !match {
                break
            }
        }
        return match
    }
}

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
    
    private let responseFactory: ResponseFactory
    private let router: MockNIOHTTPRouter
    private var middleware = [Middleware]()
    private var httpHandler: MockNIOHTTPHandler?

    var notFoundHandler: HandlerClosure? {
        get {
            httpHandler?.notFoundHandler
        }
        set {
            httpHandler?.notFoundHandler = newValue
        }
    }
    var methodRoutes: [MockHTTPMethod: MockNIOHTTPMethodRoute] = [:]
    
    init(responseFactory: ResponseFactory, router: MockNIOHTTPRouter) {
        self.responseFactory = responseFactory
        self.router = router
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
                let routeMiddleware = MockRoutesMiddleware(router: self.router,
                                                           responseFactory: self.responseFactory)
                self.httpHandler = MockNIOHTTPHandler(router: self.router,
                                                      middleware: [routeMiddleware] + self.middleware,
                                                      notFoundHandler: self.notFoundHandler)
                return channel.pipeline.addHandler(self.httpHandler!)
            }
        }
    }
    
    func add(middleware: Middleware) {
        httpHandler?.middleware.append(middleware)
    }
    
    func has<T>(middlewareOfType type: T.Type) -> Bool where T: Middleware {
        return (httpHandler?.middleware ?? []).contains { $0 is T }
    }
}

struct MockNIOHTTPMethodRoute: MockMethodRoute {
    let method: String
    let router: MockHttpRouter
}

class MockNIOHTTPRouter: MockHttpRouter {
    typealias RouteHandlerMapping = [MockHTTPRoute: HandlerClosure]
    private var routes = [String: RouteHandlerMapping]()
    
    func handlerForMethod(_ method: String, path: String, params: [String:String], headers: [String:String]) -> HandlerClosure? {
        guard let httpMethod = MockHTTPMethod(rawValue: method) else { return nil }
        let methodRoutes = routes[method] ?? RouteHandlerMapping()
        for (candidate, handler) in methodRoutes {
            if candidate.matches(method: httpMethod, path: path, params: params, headers: headers) {
                return handler
            }
        }
        return nil
    }
    
    func register(route: MockHTTPRoute, handler: HandlerClosure?) {
        guard let method = route.method?.rawValue else { return }
        var methodRoutes = routes[method] ?? RouteHandlerMapping()
        methodRoutes[route] = handler
        routes[method] = methodRoutes
    }
}

struct MockNIOHTTPRequest: MockHttpRequest {
    var eventLoop: EventLoop
    var path: String
    var queryParams: [(String, String)]
    var method: String
    var headers: [String : String]
    var body: [UInt8]
    var address: String?
    var params: [String : String]
}

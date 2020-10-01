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
internal class MockNIOHttpServer: MockNIOBaseServer, MockHttpServer {
    
    private let router = NIOHTTPRouter()
    
    var notFoundHandler: ((MockHttpRequest) -> MockHttpResponse)?
    var HEAD, GET, POST, PUT, PATCH, DELETE: MockMethodRoute
    
    override init() {
        self.DELETE = NIOHTTPMethodRoute(method: "DELETE", router: router)
        self.PATCH = NIOHTTPMethodRoute(method: "PATCH", router: router)
        self.HEAD = NIOHTTPMethodRoute(method: "HEAD", router: router)
        self.POST = NIOHTTPMethodRoute(method: "POST", router: router)
        self.GET = NIOHTTPMethodRoute(method: "GET", router: router)
        self.PUT = NIOHTTPMethodRoute(method: "PUT", router: router)
        super.init()
    }
    
    func start(_ port: Int, forceIPv4: Bool, priority: DispatchQoS.QoSClass) throws -> Void {
        
        try start(port) { (channel) -> EventLoopFuture<Void> in
            channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
                channel.pipeline.addHandler(MockNIOHTTPHandler(router: self.router))
            }
        }
    }
}

struct NIOHTTPMethodRoute: MockMethodRoute {
    let method: String
    let router: MockHttpRouter
}

class NIOHTTPRouter: MockHttpRouter {
    typealias PathHandlerMapping = [String: MockMethodRoute.HandlerClosure]
    private var routes = [String: PathHandlerMapping]()
    
    func handlerForMethod(_ method: String, path: String) -> MockMethodRoute.HandlerClosure? {
        let methodRoutes = routes[method] ?? PathHandlerMapping()
        return methodRoutes[path]
    }
    
    func register(_ method: String, path: String, handler: MockMethodRoute.HandlerClosure?) {
        var methodRoutes = routes[method] ?? PathHandlerMapping()
        methodRoutes[path] = handler
        routes[method] = methodRoutes
    }
}

class NIOHTTPResponseBodyWriter: MockHttpResponseBodyWriter {
    var buffer = ByteBuffer()
    var contentLength: Int {
        buffer.readableBytes
    }
    func write(_ data: Data) throws {
        buffer = ByteBuffer(bytes: data)
    }
}

struct NIOHTTPRequest: MockHttpRequest {
    var path: String
    var queryParams: [(String, String)]
    var method: String
    var headers: [String : String]
    var body: [UInt8]
    var address: String?
    var params: [String : String]
}

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
    private var httpHandler: MockNIOHTTPHandler?

    var router: MockNIOHTTPRouter? {
        get {
            httpHandler?.router
        }
        set {
            guard let httpHandler = self.httpHandler else { return }
            httpHandler.router = newValue
        }
    }
    
    var notFoundHandler: HandlerClosure? {
        get {
            httpHandler?.notFoundHandler
        }
        set {
            httpHandler?.notFoundHandler = newValue
        }
    }
    
    init(responseFactory: ResponseFactory) {
        self.responseFactory = responseFactory
        super.init()
    }
    
    func start(_ port: Int, forceIPv4: Bool, priority: DispatchQoS.QoSClass) throws -> Void {
        try start(port) { (channel) -> EventLoopFuture<Void> in
            channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
                self.httpHandler = MockNIOHTTPHandler(responseFactory: self.responseFactory,
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

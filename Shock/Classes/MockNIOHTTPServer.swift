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
internal class MockNIOHttpServer: MockHttpServer {
    
    private let host = "localhost"
    // TODO: make this an option?
    private let allowHalfClosure = true
    
    private let router = NIOHTTPRouter()
    private let group: MultiThreadedEventLoopGroup
    private let threadPool: NIOThreadPool
    
    private(set) var localAddress: String?
    var notFoundHandler: ((MockHttpRequest) -> MockHttpResponse)?
    var HEAD, GET, POST, PUT, PATCH, DELETE: MockMethodRoute
    
    init() {
        self.DELETE = NIOHTTPMethodRoute(method: "DELETE", router: router)
        self.PATCH = NIOHTTPMethodRoute(method: "PATCH", router: router)
        self.HEAD = NIOHTTPMethodRoute(method: "HEAD", router: router)
        self.POST = NIOHTTPMethodRoute(method: "POST", router: router)
        self.GET = NIOHTTPMethodRoute(method: "GET", router: router)
        self.PUT = NIOHTTPMethodRoute(method: "PUT", router: router)
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.threadPool = NIOThreadPool(numberOfThreads: 6)
    }
    
    func start(_ port: Int, forceIPv4: Bool, priority: DispatchQoS.QoSClass) throws -> Void {
        threadPool.start()
        
        let socketBootstrap = ServerBootstrap(group: group)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

            // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer({ (channel) -> EventLoopFuture<Void> in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
                    channel.pipeline.addHandler(MockNIOHTTPHandler(router: self.router))
                }
            })

            // Enable SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
            .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: allowHalfClosure)
        
        let channel = try { () -> Channel in
            try socketBootstrap.bind(host: host, port: port).wait()
        }()
        
        guard let channelLocalAddress = channel.localAddress else {
            fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
        }
        localAddress = "\(channelLocalAddress)"
    }
    
    func stop() {
        try! group.syncShutdownGracefully()
        try! threadPool.syncShutdownGracefully()
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

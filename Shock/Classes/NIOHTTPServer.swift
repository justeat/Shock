//
//  NIOHTTPServer.swift
//  Shock
//
//  Created by Antonio Strijdom on 30/09/2020.
//

import Foundation
import NIO
import NIOHTTP1

private final class NIOHTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    private let router: NIOHTTPRouter
    
    private func httpResponseHeadForRequestHead(_ request: HTTPRequestHead, status: HTTPResponseStatus, headers: HTTPHeaders = HTTPHeaders()) -> HTTPResponseHead {
        HTTPResponseHead(version: request.version, status: status, headers: headers)
    }
    
    private func completeResponse(_ context: ChannelHandlerContext, trailers: HTTPHeaders?) {
        _ = context.writeAndFlush(self.wrapOutboundOut(.end(trailers)))
    }
    
    private func stringForHTTPMethod(_ method: HTTPMethod) -> String {
        switch method {
        case .HEAD:
            return "HEAD"
        case .GET:
            return "GET"
        case .POST:
            return "POST"
        case .PUT:
            return "PUT"
        case .PATCH:
            return "PATCH"
        case .DELETE:
            return "DELETE"
        default:
            return ""
        }
    }
    
    private func requestForHTTPRequestHead(_ request: HTTPRequestHead) -> NIOHTTPRequest? {
        guard let url = URLComponents(string: request.uri) else { return nil }
        let path = url.path
        let queryParams =  [(String, String)]()
        let method = stringForHTTPMethod(request.method)
        let headers = request.headers.reduce(into: [String: String](), { $0[$1.0] = $1.1 })
        var body = [UInt8]()
        var address = url.host
        var params = [String: String]()
        if let queryItems = url.queryItems {
            params = queryItems.reduce(into: [String: String](), { $0[$1.name] = $1.value })
        }
        
        return NIOHTTPRequest(path: path,
                              queryParams: queryParams,
                              method: method,
                              headers: headers,
                              body: body,
                              address: address,
                              params: params)
    }
    
    private func handleResponse(_ response: HttpResponse, for request: HTTPRequestHead, in context: ChannelHandlerContext) {
        switch response {
        case .raw(_, _, _, let handler):
            if let handler = handler {
                let writer = NIOHTTPResponseBodyWriter()
                do {
                    try handler(writer)
                    var headers = HTTPHeaders()
                    headers.add(name: "content-length", value: "\(writer.contentLength)")
                    _ = context.writeAndFlush(self.wrapOutboundOut(.head(httpResponseHeadForRequestHead(request, status: .ok))))
                    _ = context.write(self.wrapOutboundOut(.body(.byteBuffer(writer.buffer))), promise: nil)
                } catch {
                    _ = context.writeAndFlush(self.wrapOutboundOut(.head(httpResponseHeadForRequestHead(request, status: .internalServerError))))
                }
            } else {
                _ = context.writeAndFlush(self.wrapOutboundOut(.head(httpResponseHeadForRequestHead(request, status: .internalServerError))))
            }
        case .movedPermanently(let location):
            var headers = HTTPHeaders()
            headers.add(name: "Location", value: location)
            _ = context.writeAndFlush(self.wrapOutboundOut(.head(httpResponseHeadForRequestHead(request, status: .movedPermanently, headers: headers))))
        case .notFound:
            _ = context.writeAndFlush(self.wrapOutboundOut(.head(httpResponseHeadForRequestHead(request, status: .notFound))))
        case .internalServerError:
            _ = context.writeAndFlush(self.wrapOutboundOut(.head(httpResponseHeadForRequestHead(request, status: .internalServerError))))
        }
        completeResponse(context, trailers: nil)
    }
    
    init(router: NIOHTTPRouter) {
        self.router = router
    }
    
    func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        
        switch reqPart {
        case .head(let request):
            let method = stringForHTTPMethod(request.method)
            let path = request.uri
            if
                let handler = router.handlerForMethod(method, path: path),
                let handlerRequest = requestForHTTPRequestHead(request) {
                let response = handler(handlerRequest)
                handleResponse(response, for: request, in: context)
            }
        case .body(_):
            break
        case .end(_):
            break
        }
    }
}

// MARK: MockHTTPServerProtocols

/// SwiftNIO implementation of mock HTTP server
class NIOHttpServer: HttpServer {
    
    fileprivate let host = "localhost"
    // TODO: make this an option?
    fileprivate let allowHalfClosure = true
    
    fileprivate let router = NIOHTTPRouter()
    fileprivate let group: MultiThreadedEventLoopGroup
    fileprivate let threadPool: NIOThreadPool
    
    private(set) var localAddress: String?
    var notFoundHandler: ((HttpRequest) -> HttpResponse)?
    var HEAD, GET, POST, PUT, PATCH, DELETE: MethodRoute
    
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
                    channel.pipeline.addHandler(NIOHTTPHandler(router: self.router))
                }
            })

            // Enable SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
            .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: allowHalfClosure)
//        let pipeBootstrap = NIOPipeBootstrap(group: group)
//            // Set the handlers that are applied to the accepted Channels
//            .channelInitializer(childChannelInitializer(channel:))
//
//            .channelOption(ChannelOptions.maxMessagesPerRead, value: 1)
//            .channelOption(ChannelOptions.allowRemoteHalfClosure, value: allowHalfClosure)
        
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

struct NIOHTTPMethodRoute: MethodRoute {
    let method: String
    let router: HttpRouter
}

class NIOHTTPRouter: HttpRouter {
    private var routes = [[String]: MethodRoute.HandlerClosure]()
    
    func handlerForMethod(_ method: String, path: String) -> MethodRoute.HandlerClosure? {
        return routes[[method, path]]
    }
    
    func register(_ method: String, path: String, handler: MethodRoute.HandlerClosure?) {
        let key = [method, path].compactMap({ $0 })
        routes[key] = handler
    }
}

class NIOHTTPResponseBodyWriter: HttpResponseBodyWriter {
    var buffer = ByteBuffer()
    var contentLength: Int {
        buffer.readableBytes
    }
    func write(_ data: Data) throws {
        buffer.setBytes(data, at: 0)
    }
}

struct NIOHTTPRequest: HttpRequest {
    var path: String
    var queryParams: [(String, String)]
    var method: String
    var headers: [String : String]
    var body: [UInt8]
    var address: String?
    var params: [String : String]
}

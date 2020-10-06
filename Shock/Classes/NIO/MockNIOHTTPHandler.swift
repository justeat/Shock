//
//  MockNIOHTTPHandler.swift
//  Shock
//
//  Created by Antonio Strijdom on 30/09/2020.
//

import Foundation
import NIO
import NIOHTTP1

class MockNIOHTTPHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    private let router: MockNIOHTTPRouter
    private let middlewareService: MiddlewareService
    
    private var httpRequest: HTTPRequestHead?
    private var handlerRequest: MockNIOHTTPRequest?
    
    init(router: MockNIOHTTPRouter, middlewareService: MiddlewareService) {
        self.router = router
        self.middlewareService = middlewareService
    }
    
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
    
    private func requestForHTTPRequestHead(_ request: HTTPRequestHead) -> MockNIOHTTPRequest? {
        guard let url = URLComponents(string: request.uri) else { return nil }
        let path = url.path
        let method = stringForHTTPMethod(request.method)
        let headers = request.headers.reduce(into: [String: String](), { $0[$1.0.lowercased()] = $1.1 })
        let body = [UInt8]()
        let address = url.host
        var params = [String: String]()
        var queryParams =  [(String, String)]()
        if let queryItems = url.queryItems {
            params = queryItems.reduce(into: [String: String](), { $0[$1.name] = $1.value })
            queryParams = queryItems.reduce(into: [(String, String)](), { $0.append(($1.name, $1.value ?? "")) })
        }
        
        return MockNIOHTTPRequest(path: path,
                              queryParams: queryParams,
                              method: method,
                              headers: headers,
                              body: body,
                              address: address,
                              params: params)
    }
    
    private func handleResponse(forResponseContext middlewareContext: MiddlewareContext, in     channelHandlerContext: ChannelHandlerContext) {
        
        // TODO
        
        let headers = middlewareContext.responseContext.headers
        let body = middlewareContext.responseContext.responseBody
        let statusCode = middlewareContext.responseContext.statusCode
        
        // Write head
        guard let requestHead = self.httpRequest else { return }
        let responseHead = httpResponseHeadForRequestHead(requestHead,
                                                          status: HTTPResponseStatus(statusCode: statusCode),
                                                          headers: HTTPHeaders(headers.map { ($0.key, $0.value) }))
        let outboundHeadData = self.wrapOutboundOut(.head(responseHead))
        channelHandlerContext.writeAndFlush(outboundHeadData, promise: nil)
        
        // Write body
        guard let _body = body else { return }
        let buffer = ByteBuffer(bytes: _body)
        let outboundBodyData = self.wrapOutboundOut(.body(.byteBuffer(buffer)))
        channelHandlerContext.writeAndFlush(outboundBodyData, promise: nil)
        
        completeResponse(channelHandlerContext, trailers: nil)
    }
    
    private func writeAndFlushHeaderResponse(status: HTTPResponseStatus, for request: HTTPRequestHead, in context: ChannelHandlerContext) {
        _ = context.writeAndFlush(self.wrapOutboundOut(.head(httpResponseHeadForRequestHead(request, status: status))))
    }
    
    private func writeAndFlushInternalServerError(for request: HTTPRequestHead, in context: ChannelHandlerContext) {
        writeAndFlushHeaderResponse(status: .internalServerError, for: request, in: context)
    }
}
    
// MARK: ChannelInboundHandler

extension MockNIOHTTPHandler: ChannelInboundHandler {
    
    func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        
        switch reqPart {
        case .head(let request):
            self.httpRequest = request
            self.handlerRequest = requestForHTTPRequestHead(request)
        case .body(buffer: var bytes):
            guard var handlerRequest = self.handlerRequest else { return }
            handlerRequest.body += bytes.readBytes(length: bytes.readableBytes) ?? []
            self.handlerRequest = handlerRequest
        case .end(_):
            guard let request = self.httpRequest else { return }
            guard let handlerRequest = self.handlerRequest else { return }
            
            if let finalContext = middlewareService.executeAll(forRequest: handlerRequest) {
                handleResponse(forResponseContext: finalContext, in: context)
            }

            self.httpRequest = nil
            self.handlerRequest = nil
        }
    }
}

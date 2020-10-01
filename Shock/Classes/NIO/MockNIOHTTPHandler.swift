//
//  MockNIOHTTPHandler.swift
//  Shock
//
//  Created by Antonio Strijdom on 30/09/2020.
//

import Foundation
import NIO
import NIOHTTP1

internal class MockNIOHTTPHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    private let router: NIOHTTPRouter
    private var httpRequest: HTTPRequestHead?
    private var handlerRequest: NIOHTTPRequest?
    
    init(router: NIOHTTPRouter) {
        self.router = router
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
    
    private func requestForHTTPRequestHead(_ request: HTTPRequestHead) -> NIOHTTPRequest? {
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
        
        return NIOHTTPRequest(path: path,
                              queryParams: queryParams,
                              method: method,
                              headers: headers,
                              body: body,
                              address: address,
                              params: params)
    }
    
    private func handleResponse(_ response: MockHttpResponse, for request: HTTPRequestHead, in context: ChannelHandlerContext) {
        
        switch response {
        case .raw(_, _, let customHeaders, let handler):
            guard let handler = handler else {
                writeAndFlushInternalServerError(for: request, in: context)
                break
            }
            let writer = NIOHTTPResponseBodyWriter()
            do {
                try handler(writer)
                var headers = HTTPHeaders()
                headers.add(name: "content-length", value: "\(writer.contentLength)")
                if let customHeaders = customHeaders {
                    for (name, value) in customHeaders {
                        headers.add(name: name, value: value)
                    }
                }
                _ = context.write(self.wrapOutboundOut(.head(httpResponseHeadForRequestHead(request, status: .ok, headers: headers))))
                if writer.contentLength > 0 {
                    _ = context.writeAndFlush(self.wrapOutboundOut(.body(.byteBuffer(writer.buffer))), promise: nil)
                }
            } catch {
                writeAndFlushInternalServerError(for: request, in: context)
            }
        case .movedPermanently(let location):
            var headers = HTTPHeaders()
            headers.add(name: "Location", value: location)
            _ = context.writeAndFlush(self.wrapOutboundOut(.head(httpResponseHeadForRequestHead(request, status: .movedPermanently, headers: headers))))
        case .notFound:
            writeAndFlushHeaderResponse(status: .notFound, for: request, in: context)
        case .internalServerError:
            writeAndFlushInternalServerError(for: request, in: context)
        }
        completeResponse(context, trailers: nil)
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
        case .end(_):
            guard let request = self.httpRequest else { return }
            if
                let handlerRequest = self.handlerRequest,
                let handler = router.handlerForMethod(handlerRequest.method, path: handlerRequest.path) {
                let response = handler(handlerRequest)
                // TODO: <- Middleware here? pre-response
                handleResponse(response, for: request, in: context)
            } else {
                _ = context.writeAndFlush(self.wrapOutboundOut(.head(httpResponseHeadForRequestHead(request, status: .notFound))))
                completeResponse(context, trailers: nil)
            }
            self.httpRequest = nil
            self.handlerRequest = nil
        }
    }
}

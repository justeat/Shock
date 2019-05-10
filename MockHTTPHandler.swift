//
//  MockHTTPHandler.swift
//  Shock
//
//  Created by Antonio Strijdom on 08/05/2019.
//

import Foundation
import NIO
import NIOHTTP1

final class MockHTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    
    private let bundle: Bundle
    
    private let routes: [MockHTTPRoute]
    
    init(bundle: Bundle = Bundle.main, routes: [MockHTTPRoute]) {
        self.bundle = bundle
        self.routes = routes
    }
 
//    fileprivate func completeResponse(_ context: ChannelHandlerContext) {
//        let promise = context.eventLoop.makePromise(of: Void.self)
//        promise.futureResult.whenComplete { (_) in
//            context.close(promise: nil)
//        }
//        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: promise)
//    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let requestPart = self.unwrapInboundIn(data)
        
        switch requestPart {
        case .head(let request):
            print("Received request: \(request)")
            guard let requestUrlPath = URL(string: request.uri)?.path else {
                print("Could not determine request path")
                let responseHead = HTTPResponseHead(version: request.version, status: HTTPResponseStatus.badRequest)
                let response = HTTPServerResponsePart.head(responseHead)
                _ = context.channel.write(response)
                return
            }
            let mockRoutes = self.routes.filter() { ($0.urlPath ?? "") == requestUrlPath }
            if let mockRoute = mockRoutes.first {
                switch mockRoute {
                case .simple(let method, let urlPath, let code, let filename):
                    let body = self.loadJson(named: filename)!
                    var responseHead = HTTPResponseHead(version: request.version, status: HTTPResponseStatus.ok)
                    responseHead.headers.add(name: "Content-Length", value: "\(body.utf8.endIndex)")
                    responseHead.headers.add(name: "Content-Type", value: "text/plain; charset=utf-8")
                    var responseBody = context.channel.allocator.buffer(capacity: 0)
                    responseBody.writeString(body)
                    _ = context.channel.write(HTTPServerResponsePart.head(responseHead))
                    _ = context.channel.write(HTTPServerResponsePart.body(.byteBuffer(responseBody)))
                    _ = context.channel.write(HTTPServerResponsePart.end(nil))
                    _ = context.channel.close()
                    break
                case .custom(let method, let urlPath, let query, let headers, let code, let filename):
                    break
                case .template(let method, let urlPath, let code, let filename, let data):
                    break
                case .redirect(let urlPath, let destination):
                    break
                case .collection(let routes):
                    break
                }
            } else {
                let responseHead = HTTPResponseHead(version: request.version, status: HTTPResponseStatus.notFound)
                let response = HTTPServerResponsePart.head(responseHead)
                _ = context.channel.writeAndFlush(response)
                _ = context.channel.close()
            }
            break
        case .body:
            break
        case .end:
            print("Request complete")
            break
        }
    }
    
//    func channelReadComplete(context: ChannelHandlerContext) {
//        context.channel.flush()
//    }
    
    // MARK: Utilities
    
    private func loadJson(named name: String) -> String? {
        
        let components = name.components(separatedBy: ".")
        let url: URL
        if components.count == 1 {
            url = bundle.url(forResource: components[0], withExtension: "json")!
        } else if components.count > 1 {
            var components = components
            let ext = components.removeLast()
            url = bundle.url(forResource: components.joined(separator: "."), withExtension: ext)!
        } else {
            url = URL(string: name)!
        }
        
        return try? String(contentsOf: url)
    }
}

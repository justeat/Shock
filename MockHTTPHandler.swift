//
//  MockHTTPHandler.swift
//  Shock
//
//  Created by Antonio Strijdom on 08/05/2019.
//

import Foundation
import NIO
import NIOHTTP1
import GRMustache

fileprivate typealias Template = GRMustacheTemplate

final class MockHTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    
    private let bundle: Bundle
    
    private let routes: [MockHTTPRoute]
    
    init(bundle: Bundle = Bundle.main, routes: [MockHTTPRoute]) {
        self.bundle = bundle
        self.routes = routes
    }
 
    fileprivate func completeResponse(_ ctx: ChannelHandlerContext) {
        _ = ctx.channel.writeAndFlush(HTTPServerResponsePart.end(nil)).then {
            ctx.channel.close()
        }
    }
    
    fileprivate func returnDataToClient(_ data: String,
                                        withHttpVersion httpVersion: HTTPVersion,
                                        context ctx: ChannelHandlerContext) {
        var responseHead = HTTPResponseHead(version: httpVersion, status: HTTPResponseStatus.ok)
        responseHead.headers.add(name: "Content-Length", value: "\(data.utf8.count)")
        responseHead.headers.add(name: "Content-Type", value: "text/plain; charset=utf-8")
        var responseBody = ctx.channel.allocator.buffer(capacity: 0)
        responseBody.write(string: data)
        _ = ctx.channel.write(HTTPServerResponsePart.head(responseHead))
        _ = ctx.channel.write(HTTPServerResponsePart.body(.byteBuffer(responseBody)))
        completeResponse(ctx)
    }
    
    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let requestPart = self.unwrapInboundIn(data)
        
        switch requestPart {
        case .head(let request):
            print("Received request: \(request)")
            guard let requestUrlPath = URL(string: request.uri)?.path else {
                print("Could not determine request path")
                let responseHead = HTTPResponseHead(version: request.version, status: HTTPResponseStatus.badRequest)
                let response = HTTPServerResponsePart.head(responseHead)
                _ = ctx.channel.write(response)
                completeResponse(ctx)
                return
            }
            var filterClosure: ((MockHTTPRoute) -> [MockHTTPRoute])! = nil
            filterClosure = {
                switch $0 {
                case .simple(_, let urlPath, _, _):
                    return urlPath == requestUrlPath ? [$0] : []
                case .custom(_, let urlPath, _, _, _, _):
                    return urlPath == requestUrlPath ? [$0] : []
                case .template(_, let urlPath, _, _, _):
                    return urlPath == requestUrlPath ? [$0] : []
                case .redirect(let urlPath, _):
                    return urlPath == requestUrlPath ? [$0] : []
                case .collection(let routes):
                    return routes.flatMap(filterClosure)
                }
            }
            let mockRoutes = self.routes.flatMap(filterClosure)
            if let mockRoute = mockRoutes.first {
                switch mockRoute {
                case .simple(_, _, _, let filename),
                     .custom(_, _, _, _, _, let filename):
                    let body = self.loadJson(named: filename)!
                    returnDataToClient(body, withHttpVersion: request.version, context: ctx)
                    break
                case .template(_, _, _, let filename, let data):
                    let template = try! Template(fromResource: filename, bundle: self.bundle)
                    let responseBody = try! template.renderObject(data)
                    returnDataToClient(responseBody, withHttpVersion: request.version, context: ctx)
                    break
                case .redirect(_, let destination):
                    var responseHead = HTTPResponseHead(version: request.version, status: HTTPResponseStatus.permanentRedirect)
                    responseHead.headers.add(name: "Location", value: destination)
                    let response = HTTPServerResponsePart.head(responseHead)
                    _ = ctx.channel.write(response)
                    completeResponse(ctx)
                    break
                case .collection(_):
                    // collections should have been flatmapped out
                    let responseHead = HTTPResponseHead(version: request.version, status: HTTPResponseStatus.internalServerError)
                    let response = HTTPServerResponsePart.head(responseHead)
                    _ = ctx.channel.write(response)
                    completeResponse(ctx)
                    break
                }
            } else {
                let responseHead = HTTPResponseHead(version: request.version, status: HTTPResponseStatus.notFound)
                let response = HTTPServerResponsePart.head(responseHead)
                _ = ctx.channel.write(response)
                completeResponse(ctx)
            }
            break
        case .body:
            break
        case .end:
            print("Request complete")
            break
        }
    }
    
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

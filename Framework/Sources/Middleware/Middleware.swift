//  Middleware.swift

import Foundation
import NIO

public typealias HandlerClosure = (MiddlewareRequestContext, MiddlewareResponseContext) -> Void

public protocol MiddlewareRequestContext: MockHttpRequest {
    var path: String { get }
    var queryParams: [(String, String)] { get }
    var method: String { get }
    var headers: [String: String] { get }
    var body: [UInt8] { get }
    var address: String? { get }
    var params: [String: String] { get }
}

public protocol MiddlewareResponseContext: AnyObject {
    var statusCode: Int { get set }
    var headers: [String: String] { get set }
    var responseBody: Data? { get set }
}

public protocol MiddlewareContext {
    var requestContext: MiddlewareRequestContext { get }
    var responseContext: MiddlewareResponseContext { get }
    var notFoundHandler: HandlerClosure? { get }
    var next: () -> Void { get }
}

public protocol Middleware {
    func execute(withContext context: MiddlewareContext)
}

class MiddlewareService {
    
    private struct _MiddlewareRequestContext: MiddlewareRequestContext, MockHttpRequest {
        let path: String
        let queryParams: [(String, String)]
        let method: String
        let headers: [String: String]
        let body: [UInt8]
        let address: String?
        let params: [String: String]
        
        init(request: MockNIOHTTPRequest) {
            self.path = request.path
            self.queryParams = request.queryParams
            self.method = request.method
            self.headers = request.headers
            self.body = request.body
            self.address = request.address
            self.params = request.params
        }
    }
    
    private class _MiddlewareResponseContext: MiddlewareResponseContext {
        var statusCode: Int = 0
        var headers: [String: String] = [:]
        var responseBody: Data?
    }
    
    private struct _MiddlewareContext: MiddlewareContext {
        let requestContext: MiddlewareRequestContext
        let responseContext: MiddlewareResponseContext
        let notFoundHandler: HandlerClosure?
        let next: () -> Void
    }
    
    private let middleware: [Middleware]
    private let notFoundHandler: HandlerClosure?

    init(middleware: [Middleware], notFoundHandler: HandlerClosure?) {
        self.middleware = middleware
        self.notFoundHandler = notFoundHandler
    }
    
    func executeAll(forRequest request: MockNIOHTTPRequest) -> EventLoopFuture<MiddlewareContext?> {
        let promise = request.eventLoop.makePromise(of: MiddlewareContext?.self)
        
        request.eventLoop.execute {
            // _MiddlewareResponseContext is a reference type that is updated across the registered middlewares
            let responseContext = _MiddlewareResponseContext()
            let context = self.executeAll(forRequest: request, middleware: self.middleware, responseContext: responseContext)
            promise.succeed(context)
        }
        
        return promise.futureResult
    }
    
    @discardableResult
    private func executeAll(forRequest request: MockNIOHTTPRequest, middleware: [Middleware], responseContext: MiddlewareResponseContext) -> MiddlewareContext? {
        
        let requestContext = _MiddlewareRequestContext(request: request)
        
        let context = _MiddlewareContext(requestContext: requestContext,
                                         responseContext: responseContext,
                                         notFoundHandler: notFoundHandler) {
            if middleware.count > 1 {
                self.executeAll(forRequest: request, middleware: Array(middleware[1...]), responseContext: responseContext)
            }
        }
        
        middleware.first?.execute(withContext: context)
        
        return context
    }
}

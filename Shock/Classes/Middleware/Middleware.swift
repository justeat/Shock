//
//  Middleware.swift
//  Shock
//
//  Created by Jack Newcombe on 01/10/2020.
//

import Foundation

public protocol MiddlewareRequestContext: MockHttpRequest {
    var path: String { get }
    var queryParams: [(String, String)] { get }
    var method: String { get }
    var headers: [String : String] { get }
    var body: [UInt8] { get }
    var address: String? { get }
    var params: [String : String] { get }
}

public protocol MiddlewareResponseContext {
    var statusCode: Int { get set }
    var headers: [String: String] { get set }
    var responseBody: Data? { get set }
}

public protocol MiddlewareContext {
    var requestContext: MiddlewareRequestContext { get }
    var responseContext: MiddlewareResponseContext { get }
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
        let headers: [String : String]
        let body: [UInt8]
        let address: String?
        let params: [String : String]
        
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
    
    private struct _MiddlewareResponseContext: MiddlewareResponseContext {
        var statusCode: Int = 0
        var headers: [String : String] = [:]
        var responseBody: Data? = nil
    }
    
    private struct _MiddlewareContext: MiddlewareContext {
        let requestContext: MiddlewareRequestContext
        let responseContext: MiddlewareResponseContext
        let next: () -> Void
    }
    
    private(set) var middleware: [Middleware] = []
    
    private var activeMiddleware: Middleware?
    
    private var context: MiddlewareContext?
    
    private var isExecuting: Bool = false
    
    func executeAll(forRequest request: MockNIOHTTPRequest) -> MiddlewareContext? {

        guard !isExecuting else { return nil }
        isExecuting = true
        
        let requestContext = _MiddlewareRequestContext(request: request)
        let responseContext = _MiddlewareResponseContext()
        
        context = _MiddlewareContext(requestContext: requestContext,
                                     responseContext: responseContext,
                                     next: next)
                
        next()
        
        return context
    }
    
    private func next() {
        guard middleware.count > 0, let context = context else { return }
        activeMiddleware = middleware.removeFirst()
        activeMiddleware?.execute(withContext: context)
    }
    
    func add(middleware mdl: Middleware) {
        middleware.append(mdl)
    }
    
}

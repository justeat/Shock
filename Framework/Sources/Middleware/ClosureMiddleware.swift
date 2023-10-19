//  ClosureMiddleware.swift

import Foundation

public struct ClosureMiddleware: Middleware {
    
    public typealias Closure = (_ request: MiddlewareRequestContext,
                                _ response: MiddlewareResponseContext,
                                _ next: () -> Void) -> Void
        
    let closure: Closure
    
    public init(_ closure: @escaping Closure) {
        self.closure = closure
    }
    
    public func execute(withContext context: MiddlewareContext) {
        closure(context.requestContext, context.responseContext, context.next)
    }
}

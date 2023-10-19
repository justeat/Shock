//  MockRoutesMiddleware.swift

import Foundation

struct MockRoutesMiddleware: Middleware {
        
    let router: MockNIOHTTPRouter

    let responseFactory: MockHTTPResponseFactory
    
    init(router: MockNIOHTTPRouter, responseFactory: MockHTTPResponseFactory) {
        self.router = router
        self.responseFactory = responseFactory
    }
    
    func execute(withContext context: MiddlewareContext) {
        
        guard let handler = router.handlerForMethod(context.requestContext.method,
                                                    path: context.requestContext.path,
                                                    params: context.requestContext.params,
                                                    headers: context.requestContext.headers) else {
            context.notFoundHandler?(context.requestContext, context.responseContext)
            return context.next()
        }
        
        handler(context.requestContext, context.responseContext)
        context.next()
    }
}

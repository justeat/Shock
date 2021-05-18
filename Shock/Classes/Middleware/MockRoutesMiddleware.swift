//
//  MockRoutesMiddleware.swift
//  Shock
//
//  Created by Jack Newcombe on 03/10/2020.
//

import Foundation

class MockRoutesMiddleware: Middleware {
        
    let router: MockNIOHTTPRouter

    let responseFactory: ResponseFactory
    
    init(router: MockNIOHTTPRouter, responseFactory: ResponseFactory) {
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

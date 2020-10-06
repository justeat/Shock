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
                                                  path: context.requestContext.path) else {
            return context.next()
        }
        
        handler(context.responseContext)
    }
}

fileprivate extension Array where Element == MockHTTPRoute {
    
    func flattened() -> Self {
        return reduce([Element]()) { array, route in
            switch route {
            case .collection(let routes):
                return array + routes.flattened()
            default:
                return array + [route]
            }
        }
    }
    
    func route(for request: MiddlewareRequestContext) -> MockHTTPRoute? {
        return flattened().first {
            switch $0 {
            case .custom(let method, let path, let query, let requestHeaders, _, _, _):
                return
                    method.rawValue == request.method &&
                    path == request.path &&
                    requestHeaders == request.headers &&
                    query == request.queryParams.reduce(into: [:]) { $0[$1.0] = $1.1 }
            case .template(let method, let path, _, _, _):
                return
                    method.rawValue == request.method &&
                    path == request.path
            case .simple(let method, let path, _, _):
                return
                    method.rawValue == request.method &&
                    path == request.path
            case .redirect(let path, _):
                return path == request.path
            default:
                return false
            }
        }
    }
    
}

//
//  MockRoutesMiddleware.swift
//  Shock
//
//  Created by Jack Newcombe on 03/10/2020.
//

import Foundation

#if canImport(GRMustache)
import GRMustache
typealias Template = GRMustacheTemplate
#elseif canImport(Mustache)
import Mustache
#endif

class TemplateHelper {
    
    let bundle: Bundle
    
    init(bundle: Bundle) {
        self.bundle = bundle
    }
    
    func load(withFileName templateFilename: String) -> Template {
        #if canImport(GRMustache)
        return try! Template(fromResource: templateFilename, bundle: bundle)
        #elseif canImport(Mustache)
        return try! Template(named: templateFilename, bundle: bundle)
        #endif
    }

    func render(withTemplate template: Template, data: Any?) -> String {
        #if canImport(GRMustache)
         return try! template.renderObject(data)
         #elseif canImport(Mustache)
         return try! template.render(data)
         #endif
    }
}

class ResponseFactory {
    
    let bundle: Bundle
    
    init(bundle: Bundle) {
        self.bundle = bundle
    }
    
    func response(withTemplateFileName templateFileName: String, data: Any) -> Data? {
        let templateHelper = TemplateHelper(bundle: bundle)
        let template = templateHelper.load(withFileName: templateFileName)
        let responseData: String = templateHelper.render(withTemplate: template, data: data)
        return responseData.data(using: .utf8)
    }
    
    func response(fromFileNamed name: String) -> Data? {

        let components = name.components(separatedBy: ".")
        let _url: URL?

        switch components.count {
        case 0:
            _url = URL(string: name)
        case 1:
            _url = bundle.url(forResource: components[0], withExtension: "json")
        default:
            var components = components
            let ext = components.removeLast()
            _url = bundle.url(forResource: components.joined(separator: "."), withExtension: ext)!
        }

        guard let url = _url else { return nil }
        return try? Data(contentsOf: url)
    }
    
}

class MockRoutesMiddleware: Middleware {
    
    let router: MockNIOHTTPRouter
    
    let responseFactory: ResponseFactory
    
    
    init(router: MockNIOHTTPRouter, responseFactory: ResponseFactory) {
        self.router = router
        self.responseFactory = responseFactory
    }
    
    func execute(withContext context: MiddlewareContext) {
        
        guard let route = router.handlerForMethod(context.requestContext.method,
                                                  path: context.requestContext.path) else {
            return context.next()
        }
        
        var responseContext = context.responseContext
                
        let response = route(context.requestContext)
        
        switch response {
        case .raw(let code, _, let headers, let handler):
            responseContext.statusCode = code
            responseContext.headers = headers ?? responseContext.headers
            let writer = MockNIOHTTPResponseBodyWriter()
            try? handler?(writer)
            if let _data = writer.buffer.readBytes(length: writer.contentLength) {
                responseContext.responseBody = Data(_data)
            }
        default:
            break
        }
        
        assert(responseContext.statusCode > 0, "Failed to setup response")
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

//
//  MockHTTPServerProtocols.swift
//  Shock
//
//  Created by Antonio Strijdom on 30/09/2020.
//

import Foundation

public protocol HttpRouter {
    func register(_ method: String, path: String, handler: ((HttpRequest) -> HttpResponse)?)
}

public protocol MethodRoute {
    typealias HandlerClosure = (HttpRequest) -> HttpResponse
    var method: String { get }
    var router: HttpRouter { get }
}

public extension MethodRoute {
    subscript(path: String) -> HandlerClosure? {
        set {
            router.register(method, path: path, handler: newValue)
        }
        get { return nil }
    }
}

protocol HttpServer {
    var methodRoutes: [MockHTTPMethod: NIOHTTPMethodRoute] { get }
    var notFoundHandler: ((HttpRequest) -> HttpResponse)? { get set }
    func start(_ port: Int, forceIPv4: Bool, priority: DispatchQoS.QoSClass) throws -> Void
    func stop()
}

public protocol HttpResponseBodyWriter {
    func write(_ data: Data) throws
}

public enum HttpResponse {
    case raw(Int, String, [String: String]?, ((HttpResponseBodyWriter) throws -> Void)?)
    case movedPermanently(String)
    case notFound
    case internalServerError
}

public protocol HttpRequest: CacheableRequest {}

//
//  MockHTTPServerProtocols.swift
//  Shock
//
//  Created by Antonio Strijdom on 30/09/2020.
//

import Foundation

typealias HandlerClosure = (MiddlewareRequestContext, MiddlewareResponseContext) -> Void

protocol MockHttpRouter {
    func register(_ method: String, path: String, handler: HandlerClosure?)
}

protocol MockMethodRoute {
    var method: String { get }
    var router: MockHttpRouter { get }
}

extension MockMethodRoute {
    subscript(path: String) -> HandlerClosure? {
        set {
            router.register(method, path: path, handler: newValue)
        }
        get { return nil }
    }
}

protocol MockHttpServer {
    var methodRoutes: [MockHTTPMethod: MockNIOHTTPMethodRoute] { get }
    var notFoundHandler: HandlerClosure? { get set }
    func start(_ port: Int, forceIPv4: Bool, priority: DispatchQoS.QoSClass) throws -> Void
    func stop()
}

public protocol MockHttpRequest: CacheableRequest {}


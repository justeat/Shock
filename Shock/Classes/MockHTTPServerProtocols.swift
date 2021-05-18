//
//  MockHTTPServerProtocols.swift
//  Shock
//
//  Created by Antonio Strijdom on 30/09/2020.
//

import Foundation

protocol MockHttpRouter {
    func register(route: MockHTTPRoute, handler: HandlerClosure?)
}

protocol MockMethodRoute {
    var method: String { get }
    var router: MockHttpRouter { get }
}

extension MockMethodRoute {
    subscript(route: MockHTTPRoute) -> HandlerClosure? {
        set {
            router.register(route: route, handler: newValue)
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


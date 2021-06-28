//
//  MockHTTPServerProtocols.swift
//  Shock
//
//  Created by Antonio Strijdom on 30/09/2020.
//

import Foundation

protocol MockHttpRouter {
    var requiresRouteMiddleware: Bool { get }
    mutating func register(route: MockHTTPRoute, handler: HandlerClosure?)
}

protocol MockHttpServer {
    var notFoundHandler: HandlerClosure? { get set }
    func register(route: MockHTTPRoute, handler: HandlerClosure?)
    func start(_ port: Int, forceIPv4: Bool, priority: DispatchQoS.QoSClass) throws -> Void
    func stop()
}

public protocol MockHttpRequest: CacheableRequest {}


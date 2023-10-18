//  MockHTTPServerProtocols.swift

import Foundation

protocol MockHttpRouter {
    var requiresRouteMiddleware: Bool { get }
    mutating func register(route: MockHTTPRoute, handler: HandlerClosure?)
}

protocol MockHttpServer {
    var notFoundHandler: HandlerClosure? { get set }
    func register(route: MockHTTPRoute, handler: HandlerClosure?)
    func start(_ port: Int, forceIPv4: Bool, priority: DispatchQoS.QoSClass) throws
    func stop()
}

public protocol MockHttpRequest: CacheableRequest {}

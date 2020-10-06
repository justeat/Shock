//
//  MockHTTPServerProtocols.swift
//  Shock
//
//  Created by Antonio Strijdom on 30/09/2020.
//

import Foundation

protocol MockHttpRouter {
    func register(_ method: String, path: String, handler: ((MockHttpRequest) -> MockHttpResponse)?)
}

protocol MockMethodRoute {
    typealias HandlerClosure = (MockHttpRequest) -> MockHttpResponse
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
    var notFoundHandler: ((MockHttpRequest) -> MockHttpResponse)? { get set }
    func start(_ port: Int, forceIPv4: Bool, priority: DispatchQoS.QoSClass) throws -> Void
    func stop()
}

protocol MockHttpResponseBodyWriter {
    func write(_ data: Data) throws
}

enum MockHttpResponse {
    case raw(Int, String, [String: String]?, ((MockHttpResponseBodyWriter) throws -> Void)?)
    case movedPermanently(String)
    case notFound
    case internalServerError
}

public protocol MockHttpRequest: CacheableRequest {}


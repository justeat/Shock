//
//  MockAPI.swift
//  Shock
//
//  Created by Jack Newcombe on 27/06/2018.
//  Copyright © 2018 Just Eat. All rights reserved.
//

// Force tries are bad in the app but in a test-case it's good to have a crash
// if server unavailable
// swiftlint:disable force_try

import Foundation

public class MockServer {
    
    /// The range in which to find a free port on which to launch the server
    private let portRange: ClosedRange<Int>
    
    private var httpServer = MockNIOHttpServer()
    private var socketServer: MockNIOSocketServer?
    
    private let responseFactory: ResponseFactory
    
    private lazy var middleware: MockRoutesMiddleware = {
        let middleware = MockRoutesMiddleware(router: MockNIOHTTPRouter(),
                                              responseFactory: responseFactory)
        httpServer.add(middleware: middleware)
        return middleware
    }()
    
    public var onRequestReceived: ((MockHTTPRoute, CacheableRequest) -> Void)?
    
    public var selectedHTTPPort = 0
    public var selectedSocketPort = 0
    
    public var loggingClosure: ((String?) -> Void)?
    
    public convenience init(port: Int = 9000, bundle: Bundle = Bundle.main) {
        self.init(portRange: port...port, bundle: bundle)
    }
    
    public init(portRange: ClosedRange<Int>, bundle: Bundle = Bundle.main) {
        self.portRange = portRange
        self.responseFactory = ResponseFactory(bundle: bundle)
    }
    
    // MARK: Server managements
    
    public func start(priority: DispatchQoS.QoSClass = .default) {
        var httpStarted = false
        let socketServerRequired = socketServer != nil
        var socketStarted = false
        for i in portRange {
            let proposedPort = i
            do {
                if !httpStarted {
                    try httpServer.start(proposedPort, forceIPv4: true, priority: priority)
                    selectedHTTPPort = proposedPort
                    httpStarted = true
                    loggingClosure?("SUCCESS: Opened HTTP server on port: \(i)")
                } else if !socketStarted && socketServerRequired {
                    try socketServer?.start(proposedPort)
                    selectedSocketPort = proposedPort
                    socketStarted = true
                    loggingClosure?("SUCCESS: Opened Socket server on port: \(i)")
                }
                if httpStarted && (socketStarted || !socketServerRequired) {
                    return
                }
            } catch _ {
                loggingClosure?("NOTE: Failed to open server on port: \(i), \(portRange.upperBound - i) remaining")
                continue
            }
        }
        loggingClosure?("""
ERROR: Failed to open server on port in range \(portRange.upperBound)...\(portRange.lowerBound).
Run `netstat -anptcp | grep LISTEN` to check which ports are in use.")
""")
    }
    
    public func stop() {
        httpServer.stop()
        loggingClosure?("SUCCESS: Closed server on port: \(selectedHTTPPort)")
    }
    
    /// Indicates whether a 404 status should be sent for requests that do
    /// not have a matching route
    public var shouldSendNotFoundForMissingRoutes: Bool {
        get {
            httpServer.notFoundHandler != nil            
        }
        set {
            if newValue {
                httpServer.notFoundHandler = { _, response in
                    response.statusCode = 404
                    response.responseBody = nil
                }
            } else {
                httpServer.notFoundHandler = nil
            }
        }
    }
    
    public var hostURL: String {
        return "http://localhost:\(selectedHTTPPort)"
    }
    
    // MARK: Mock setup
    
    public func setup(route: MockHTTPRoute) {
        
        switch route {
        case .collection(let routes):
            routes.forEach { self.setup(route: $0) }
            return
        default:
            break
        }

        
        guard let method = route.method, let path = route.urlPath else {
            self.loggingClosure?("ERROR: route was missing a field")
            return
        }
        
        middleware.router.register(route: route) { request, response in
            
            switch route {
            case .redirect(_, let destination):
                response.statusCode = 301
                response.headers["Location"] = destination
                return
            case .timeout(_, _, let timeoutInSeconds):
                sleep(UInt32(timeoutInSeconds))
                return
            default:
                break
            }
            
            response.statusCode = route.statusCode ?? 0
            route.responseHeaders?.map { response.headers[$0.key] = $0.value }
            
            var data: Data?
            
            if let filename = route.filename {
                if let templateInfo = route.templateInfo {
                    data = self.responseFactory.response(withTemplateFileName: filename, data: templateInfo)
                } else {
                    data = self.responseFactory.response(fromFileNamed: filename)
                }
            }
            
            response.responseBody = data
        }
        
    }
    
    public func setupSocket(route: MockSocketRoute) {
        guard selectedSocketPort == 0 else {
            self.loggingClosure?("Server socket already running")
            return
        }
        let socketServer = MockNIOSocketServer()
        socketServer.loggingClosure = loggingClosure
        socketServer.socketDataHandler = MockSocketResponseFactory().responseFromRoute(route: route)
        self.socketServer = socketServer
    }
    
    public func add(middleware: Middleware) {
        httpServer.add(middleware: middleware)
    }
    
}

// MARK: Utils

fileprivate func dictionary(from query: [(String, String)]) -> [String: String] {
    var dict = [String: String]()
    query.forEach { dict[$0.0] = $0.1 }
    return dict
}

public protocol CacheableRequest {
    var path: String { get }
    var queryParams: [(String, String)] { get }
    var method: String { get }
    var headers: [String: String] { get }
    var body: [UInt8] { get }
    var address: String? { get }
    var params: [String: String] { get }
}

fileprivate extension Dictionary where Key == String, Value == String {
    
    func contains(_ dictionary: [Key: Value], caseSensitive: Bool = true) -> Bool {
        for (key, value) in dictionary {
            var expectedValue = self[key] ?? self[key.lowercased()]
            if expectedValue != value {
                return false
            }
        }
        return true
    }
    
}

//
//  MockHTTPRoute.swift
//  Shock
//
//  Created by Jack Newcombe on 27/06/2018.
//  Copyright © 2018 Just Eat. All rights reserved.
//

import Foundation

public struct MockHTTPRoute {

    // MARK: Request fields

    public var urlPath: String
    public var method: MockHTTPMethod
    public var requestHeaders: [String: String] = [:]
    public var query: [String: String] = [:]

    // MARK: Response fields

    public var statusCode: Int = 200
    public var responseHeaders: [String: String] = [:]
    public var filename: String?
    public var templateInfo: [String: Any]?
    public var timeoutInSeconds: Int?

    public init(
        urlPath: String,
        method: MockHTTPMethod,
        requestHeaders: [String: String] = [:],
        query: [String: String] = [:],
        statusCode: Int = 200,
        responseHeaders: [String: String] = [:],
        filename: String? = nil,
        templateInfo: [String: Any]? = nil,
        timeoutInSeconds: Int? = nil
    ) {
        self.urlPath = urlPath
        self.method = method
        self.requestHeaders = requestHeaders
        self.query = query
        self.statusCode = statusCode
        self.responseHeaders = responseHeaders
        self.filename = filename
        self.templateInfo = templateInfo
        self.timeoutInSeconds = timeoutInSeconds
    }

    public static func simple(
        method: MockHTTPMethod,
        urlPath: String,
        code: Int,
        filename: String?
    ) -> MockHTTPRoute {
        MockHTTPRoute(urlPath: urlPath, method: method, statusCode: code, filename: filename)
    }

    public static func custom(
        method: MockHTTPMethod,
        urlPath: String,
        query: [String: String],
        requestHeaders: [String: String],
        responseHeaders: [String: String],
        code: Int,
        filename: String?
    ) -> MockHTTPRoute {
        MockHTTPRoute(
            urlPath: urlPath,
            method: method,
            requestHeaders: requestHeaders,
            query: query,
            statusCode: code,
            responseHeaders: responseHeaders,
            filename: filename
        )
    }

    public static func template(
        method: MockHTTPMethod,
        urlPath: String,
        code: Int,
        filename: String?,
        templateInfo: [String: AnyHashable?]
    ) -> MockHTTPRoute {
        MockHTTPRoute(
            urlPath: urlPath,
            method: method,
            statusCode: code,
            filename: filename,
            templateInfo: templateInfo
        )
    }

    public static func redirect(
        urlPath: String,
        destination: String
    ) -> MockHTTPRoute {
        MockHTTPRoute(
            urlPath: urlPath,
            method: .get,
            statusCode: 301,
            responseHeaders: ["Location": destination],
            filename: destination
        )
    }

    public static func timeout(
        method: MockHTTPMethod,
        urlPath: String,
        timeoutInSeconds: Int = 120
    ) -> MockHTTPRoute {
        MockHTTPRoute(
            urlPath: urlPath,
            method: method,
            timeoutInSeconds: timeoutInSeconds
        )
    }

    @available(*, deprecated, message: "Use MockServer.setup(routes:) directly")
    public static func collection(
        routes: [MockHTTPRoute]
    ) -> [MockHTTPRoute] {
        routes
    }
}

extension Array where Element == MockHTTPRoute {
    @available(*, deprecated, message: "Use MockServer.setup(routes:) directly")
    public static func collection(
        routes: [MockHTTPRoute]
    ) -> [MockHTTPRoute] {
        routes
    }
}

/// The philosophy for Equatable/Hashable `MockHTTPRoute` is anything in the request
/// part of the route (e.g. `method` or `urlPath`) are part of the identify of the route
extension MockHTTPRoute: Equatable {    
    public static func == (lhs: MockHTTPRoute, rhs: MockHTTPRoute) -> Bool {
        lhs.method == rhs.method &&
            lhs.urlPath.pathMatches(rhs.urlPath) &&
            lhs.query == rhs.query &&
            headers(lhs.requestHeaders, contains: rhs.requestHeaders)
    }
    
    private static func headers(_ lhs: [String:String], contains rhs: [String:String]) -> Bool {
        guard !(lhs.isEmpty && rhs.isEmpty) else { return true }
        var bigger = lhs
        var smaller = rhs
        if smaller.count != bigger.count {
            bigger = lhs.count > rhs.count ? lhs : rhs
            smaller = lhs.count < rhs.count ? lhs : rhs
        }
        guard !smaller.isEmpty else { return true }
        for outer in smaller {
            let result = bigger.contains() { (key: String, value: String) in
                key.lowercased() == outer.key.lowercased() && value.lowercased() == outer.value.lowercased()
            }
            if result {
                return true
            }
        }
        return false
    }
    
    public func matches(method: MockHTTPMethod, path: String, params: [String:String], headers: [String:String]) -> Bool {
        guard !method.rawValue.isEmpty else { return false }
        guard !path.isEmpty else { return false }
        return self == MockHTTPRoute(urlPath: path, method: method, requestHeaders: headers, query: params)
    }
}

//
//  MockHTTPRoute.swift
//  Shock
//
//  Created by Jack Newcombe on 27/06/2018.
//  Copyright © 2018 Just Eat. All rights reserved.
//

import Foundation

public enum MockHTTPRoute {
    
    case simple(
        method: MockHTTPMethod,
        urlPath: String,
        code: Int,
        filename: String?
    )
    
    case custom(
        method: MockHTTPMethod,
        urlPath: String,
        query: [String: String],
        requestHeaders: [String: String],
        responseHeaders: [String: String],
        code: Int,
        filename: String?
    )
    
    case template(
        method: MockHTTPMethod,
        urlPath: String,
        code: Int,
        filename: String?,
        templateInfo: [String: Any?]
    )
    
    case redirect(
        urlPath: String,
        destination: String
    )
    
    case collection(
        routes: [MockHTTPRoute]
    )
    
    case timeout(
        method: MockHTTPMethod,
        urlPath: String,
        timeoutInSeconds: Int = 120
    )
    
    // Request fields
    
    public var urlPath: String? {
        switch self {
        case .simple(_, let urlPath, _, _),
             .custom(_, let urlPath, _, _, _, _, _),
             .template(_, let urlPath, _, _, _),
             .redirect(let urlPath, _),
             .timeout(_, let urlPath, _):
            return urlPath
        case .collection:
            return nil
        }
    }
    
    public var method: MockHTTPMethod? {
        switch self {
        case .simple(let method, _, _, _),
             .custom(let method, _, _, _, _, _, _),
             .template(let method, _, _, _, _),
             .timeout(let method, _, _):
            return method
        case .redirect:
            return .get
        case .collection:
            return nil
        }
    }
    
    public var requestHeaders: [String: String]? {
        switch self {
        case .custom(_, _, _, let headers, _, _, _):
            return headers
        case .simple, .template, .redirect, .collection, .timeout:
            return nil
        }
    }
    
    public var query: [String: String]? {
        switch self {
        case .custom(_, _, let query, _, _, _, _):
            return query
        case .simple, .template, .redirect, .collection, .timeout:
            return nil
        }
    }
    
    // Response fields
    
    var statusCode: Int? {
        switch self {
        case .custom(_, _, _, _, _, let statusCode, _),
             .simple(_, _, let statusCode, _),
             .template(_, _, let statusCode, _, _):
             return statusCode
        case .redirect:
            return 301
        default:
            return nil
        }
    }
    
    var responseHeaders: [String: String]? {
        switch self {
        case .custom(_, _, _, _, let responseHeaders, _, _):
            return responseHeaders
        default:
            return nil
        }
    }
    
    var filename: String? {
        switch self {
        case .custom(_, _, _, _, _, _, let filename),
             .simple(_, _, _, let filename),
             .template(_, _, _, let filename, _):
            return filename
        default:
            return nil
        }
    }
    
    var templateInfo:  [String: Any]? {
        switch self {
        case .template(_, _, _, _, let templateInfo):
            return templateInfo
        default:
            return nil
        }
    }
    
    var timeoutInSeconds: Int? {
        switch self {
        case .timeout(_, _, let timeoutInSeconds):
            return timeoutInSeconds
        default:
            return nil
        }
    }
    
}

extension MockHTTPRoute: Hashable {
    public static func == (lhs: MockHTTPRoute, rhs: MockHTTPRoute) -> Bool {
        if case MockHTTPRoute.simple(let lhsMethod, let lhsUrlPath, let _, _) = lhs,
           case MockHTTPRoute.simple(let rhsMethod, let rhsUrlPath, let _, _) = rhs {
            return lhsMethod == rhsMethod && lhsUrlPath == rhsUrlPath
        }
        if case MockHTTPRoute.custom(let lhsMethod, let lhsUrlPath, let lhsQuery, let lhsRequestHeaders, _, let _, _) = lhs,
           case MockHTTPRoute.custom(let rhsMethod, let rhsUrlPath, let rhsQuery, let rhsRequestHeaders, _, let _, _) = rhs {
            return lhsMethod == rhsMethod && lhsUrlPath == rhsUrlPath && lhsQuery == rhsQuery && lhsRequestHeaders == rhsRequestHeaders
        }
        if case MockHTTPRoute.template(let lhsMethod, let lhsUrlPath, let _, _, _) = lhs,
           case MockHTTPRoute.template(let rhsMethod, let rhsUrlPath, let _, _, _) = rhs {
            return lhsMethod == rhsMethod && lhsUrlPath == rhsUrlPath
        }
        if case MockHTTPRoute.redirect(let lhsUrlPath, _) = lhs,
           case MockHTTPRoute.redirect(let rhsUrlPath, _) = rhs {
            return lhsUrlPath == rhsUrlPath
        }
        if case MockHTTPRoute.timeout(let lhsMethod, let lhsUrlPath, _) = lhs,
           case MockHTTPRoute.timeout(let rhsMethod, let rhsUrlPath, _) = rhs {
            return lhsMethod == rhsMethod && lhsUrlPath == rhsUrlPath
        }
        if case MockHTTPRoute.collection(let lhsRoutes) = lhs,
           case MockHTTPRoute.collection(let rhsRoutes) = rhs {
            return lhsRoutes.elementsEqual(rhsRoutes)
        }
        return false
    }
}

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
    
    public var timeoutInSeconds: Int? {
        switch self {
        case .timeout(_, _, let timeoutInSeconds):
            return timeoutInSeconds
        case .simple, .template, .redirect, .collection, .custom:
            return nil
        }
    }
}

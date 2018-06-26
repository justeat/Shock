//
//  MockHTTPRoute.swift
//  Shock
//
//  Created by Jack Newcombe on 05/10/2017.
//

import Foundation

public enum MockHTTPRoute {
	
	case simple(
		method: MockHTTPMethod,
		url: String,
		code: Int,
		filename: String
	)
	
	case custom(
		method: MockHTTPMethod,
		url: String,
		query: [String: String],
		headers: [String: String],
		code: Int,
		filename: String
	)
	
	case template(
		method: MockHTTPMethod,
		url: String,
		code: Int,
		filename: String,
		data: [String: Any?]
	)
	
	case redirect(
		url: String,
		destination: String
	)
	
	case collection(
		routes: [MockHTTPRoute]
	)
	
	public var url: String? {
		switch self {
		case .simple(_, let url, _, _),
		     .custom(_, let url, _, _, _, _),
		     .template(_, let url, _, _, _),
		     .redirect(let url, _):
			return url
		case .collection:
			return nil
		}
	}
	
	public var method: MockHTTPMethod? {
		switch self {
		case .simple(let method, _, _, _),
		     .custom(let method, _, _, _, _, _),
		     .template(let method, _, _, _, _):
			return method
		case .redirect:
			return .GET
        case .collection:
			return nil
		}
	}
	
	public var headers: [String: String]? {
		switch self {
		case .custom(_, _, _, let headers, _, _):
			return headers
        case .simple, .template, .redirect, .collection:
			return nil
		}
	}

	public var query: [String: String]? {
		switch self {
		case .custom(_, _, let query, _, _, _):
			return query
        case .simple, .template, .redirect, .collection:
             return nil
		}
	}

}

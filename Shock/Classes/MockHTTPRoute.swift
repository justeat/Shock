//
//  MockHTTPRoute.swift
//  Pods
//
//  Created by Jack Newcombe on 05/10/2017.
//
//

import Foundation

public enum MockHTTPRoute {
	
	case simple(
		method: MockHTTPMethod,
		url: String,
		filename: String
	)
	
	case template(
		method: MockHTTPMethod,
		url: String,
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
		case .simple(_, let url, _),
		     .template(_, let url, _, _),
		     .redirect(let url, _):
			return url
		default:
			return nil
		}
	}
	
	public var method: MockHTTPMethod? {
		switch self {
		case .simple(let method, _, _),
		     .template(let method, _, _, _):
			return method
		case .redirect:
			return .GET
		default:
			return nil
		}
	}
	
}

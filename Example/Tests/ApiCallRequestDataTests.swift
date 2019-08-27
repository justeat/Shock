//
//  ApiCallRequestData.swift
//  Shock_Example
//
//  Created by Sneha Swamy on 21/08/2019.
//  Copyright © 2019 Just Eat. All rights reserved.
//

import XCTest
@testable import Shock

class ApiCallRequestDataTests: XCTestCase {
    
    var server: MockServer!
    var requestsCache = RequestsCache()
    
    struct RequestsCache {
        var cache: [(route: MockHTTPRoute, request: CacheableRequest)] = []
    }
    
    override func setUp() {
        super.setUp()
        server = MockServer(port: 9090, bundle: Bundle(for: Tests.self))
        server.start()
        server.onRequestReceived = { route, request in
            self.requestsCache.cache.append((route, request))
        }
    }
    
    override func tearDown() {
        server.stop()
        super.tearDown()
    }
    
    func testGetApiCallRequestData() {
        let route: MockHTTPRoute = .simple(method: .get, urlPath: "/simple", code: 200, filename: "testSimpleRoute.txt")
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.get(url: "\(server.hostURL)/simple") { code, body, headers in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testSimpleRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
        
        // Check if the API call request data is accessible
        for (route, request) in requestsCache.cache{
            XCTAssertTrue(route.urlPath == "/simple")
            XCTAssertTrue(request.path == "/simple")
        }
    }
}

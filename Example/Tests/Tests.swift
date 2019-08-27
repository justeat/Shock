//
//  Tests.swift
//  Shock
//
//  Created by Jack Newcombe on 27/06/2018.
//  Copyright © 2018 Just Eat. All rights reserved.
//

import XCTest
@testable import Shock

class Tests: XCTestCase {
    
    var server: MockServer!
    
    override func setUp() {
        super.setUp()
        server = MockServer(port: 9090, bundle: Bundle(for: Tests.self))
        server.start()
    }
    
    override func tearDown() {
        server.stop()
        super.tearDown()
    }
    
    func testSimpleRoute() {
        let route: MockHTTPRoute = .simple(method: .get, urlPath: "/simple", code: 200, filename: "testSimpleRoute.txt")
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.get(url: "\(server.hostURL)/simple") { code, body, headers in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testSimpleRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testRedirectRoute() {
        let route: MockHTTPRoute = .collection(routes: [
            .redirect(urlPath: "/redirect", destination: "/destination"),
            .simple(method: .get, urlPath: "/destination", code: 200, filename: "testRedirectRoute.txt")
            ])
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body after redirect")
        
        HTTPClient.get(url: "\(server.hostURL)/redirect") { code, body, headers in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testRedirectRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testRouteProperties() {
        let emptyRoute: MockHTTPRoute = .collection(routes: [])
        XCTAssertNil(emptyRoute.urlPath)
        XCTAssertNil(emptyRoute.method)
    }
}

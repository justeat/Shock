//
//  Tests.swift
//  Shock
//
//  Created by Jack Newcombe on 01/11/2017.
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
        super.tearDown()
		server.stop()
    }
    
	func testSimpleRoute() {
		
		let route: MockHTTPRoute = .simple(method: .GET, urlPath: "/simple", code: 200, filename: "testSimpleRoute.txt")
		server.setup(route: route)
		
		let expectation = self.expectation(description: "Expect 200 response with response body")
		
		HTTPClient.get(url: "\(server.hostURL)/simple") { (code, responseBody) in
			XCTAssertEqual(code, 200)
			XCTAssertEqual(responseBody, "testSimpleRoute test fixture\n")
			expectation.fulfill()
		}
		self.waitForExpectations(timeout: 2.0, handler: nil)
	}
    
	func testRedirectRoute() {
		
		let route: MockHTTPRoute = .collection(routes: [
			.redirect(urlPath: "/redirect", destination: "/destination"),
			.simple(method: .GET, urlPath: "/destination", code: 200, filename: "testRedirectRoute.txt")
		])
		server.setup(route: route)
		
		let expectation = self.expectation(description: "Expect 200 response with response body after redirect")
		
		HTTPClient.get(url: "\(server.hostURL)/redirect") { (code, responseBody) in
			XCTAssertEqual(code, 200)
			XCTAssertEqual(responseBody, "testRedirectRoute test fixture\n")
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

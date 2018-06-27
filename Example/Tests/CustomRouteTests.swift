//
//  CustomRouteTests.swift
//  Shock
//
//  Created by Jack Newcombe on 27/06/2018.
//  Copyright © 2018 Just Eat. All rights reserved.
//

import XCTest
@testable import Shock

class CustomRouteTests: XCTestCase {
    
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
    
    func testCustomRoute() {
        let route: MockHTTPRoute = .custom(method: .GET, urlPath: "/custom", query: [:], headers: [:], code: 200, filename: "testCustomRoute.txt")
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.get(url: "\(server.hostURL)/custom") { (code, responseBody) in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(responseBody, "testCustomRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
        
    }
    
    func testCustomRouteWithHeader() {
        
        let customHeaders = [ "My-Custom-Header" : "my-header-value" ]
        
        let route: MockHTTPRoute = .custom(
            method: .GET,
            urlPath: "/custom-with-header",
            query: [:],
            headers: customHeaders,
            code: 200,
            filename: "testCustomRoute.txt"
        )
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.get(url: "\(server.hostURL)/custom-with-header", headers: customHeaders) { (code, responseBody) in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(responseBody, "testCustomRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testCustomRouteWithoutHeader() {
        
        let customHeaders = [ "My-Custom-Header" : "my-header-value" ]
        
        let route: MockHTTPRoute = .custom(
            method: .GET,
            urlPath: "/custom-with-header",
            query: [:],
            headers: customHeaders,
            code: 200,
            filename: "testCustomRoute.txt"
        )
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 404 response with empty response body")
        
        HTTPClient.get(url: "\(server.hostURL)/custom-with-header") { (code, responseBody) in
            expectation.fulfill()
            XCTAssertEqual(code, 404)
            XCTAssertEqual(responseBody, "")
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testCustomRouteWithQuery() {
        
        let query = "item1=value1&item2=value2"
        
        let route: MockHTTPRoute = .custom(
            method: .GET,
            urlPath: "/custom-with-query",
            query: [ "item1": "value1", "item2": "value2" ],
            headers: [:],
            code: 200,
            filename: "testCustomRoute.txt"
        )
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.get(url: "\(server.hostURL)/custom-with-query?\(query)") { (code, responseBody) in
            expectation.fulfill()
            XCTAssertEqual(code, 200)
            XCTAssertEqual(responseBody, "testCustomRoute test fixture\n")
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testCustomRouteWithoutQuery() {
        
        let route: MockHTTPRoute = .custom(
            method: .GET,
            urlPath: "/custom-with-query",
            query: [ "item1": "value1", "item2": "value2" ],
            headers: [:],
            code: 200,
            filename: "testCustomRoute.txt"
        )
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 404 response with empty response body")
        
        HTTPClient.get(url: "\(server.hostURL)/custom-with-query") { (code, responseBody) in
            expectation.fulfill()
            XCTAssertEqual(code, 404)
            XCTAssertEqual(responseBody, "")
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
}

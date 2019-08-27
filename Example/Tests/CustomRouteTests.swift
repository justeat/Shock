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
    let timeout: TimeInterval = 2.0
    
    override func setUp() {
        super.setUp()
        server = MockServer(port: 9090, bundle: Bundle(for: Tests.self))
        server.start()
    }
    
    override func tearDown() {
        server.stop()
        super.tearDown()
    }
    
    func testCustomRoute() {
        let route: MockHTTPRoute = .custom(method: .get,
                                           urlPath: "/custom",
                                           query: [:],
                                           requestHeaders: [:],
                                           responseHeaders: [:],
                                           code: 200,
                                           filename: "testCustomRoute.txt")
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.get(url: "\(server.hostURL)/custom") { code, body, headers in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testCustomRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }
    
    func testCustomRouteWithRequestHeaders() {
        let customHeaders = ["My-Custom-Header": "my-header-value"]
        let route: MockHTTPRoute = .custom(
            method: .get,
            urlPath: "/custom-with-header",
            query: [:],
            requestHeaders: customHeaders,
            responseHeaders: [:],
            code: 200,
            filename: "testCustomRoute.txt"
        )
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.get(url: "\(server.hostURL)/custom-with-header", headers: customHeaders) { code, body, headers in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testCustomRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }
    
    func testCustomRouteWithoutRequestHeader() {
        let customHeaders = ["My-Custom-Header" : "my-header-value"]
        let route: MockHTTPRoute = .custom(
            method: .get,
            urlPath: "/custom-with-header",
            query: [:],
            requestHeaders: customHeaders,
            responseHeaders: [:],
            code: 200,
            filename: "testCustomRoute.txt"
        )
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 404 response with empty response body")
        
        HTTPClient.get(url: "\(server.hostURL)/custom-with-header") { code, body, headers in
            expectation.fulfill()
            XCTAssertEqual(code, 404)
            XCTAssertEqual(body, "")
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }
    
    func testCustomRouteWithResponseHeaders() {
        let customHeaders = ["Server-Custom-Header": "server-header-value"]
        let route: MockHTTPRoute = .custom(
            method: .get,
            urlPath: "/custom-with-header",
            query: [:],
            requestHeaders: [:],
            responseHeaders: customHeaders,
            code: 200,
            filename: "testCustomRoute.txt"
        )
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.get(url: "\(server.hostURL)/custom-with-header") { code, body, headers in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testCustomRoute test fixture\n")
            for (k, v) in customHeaders {
                XCTAssertEqual(headers[k], v)
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }
    
    func testCustomRouteWithQueryParameters() {
        let query = "item1=value1&item2=value2"
        let route: MockHTTPRoute = .custom(
            method: .get,
            urlPath: "/custom-with-query",
            query: ["item1": "value1", "item2": "value2"],
            requestHeaders: [:],
            responseHeaders: [:],
            code: 200,
            filename: "testCustomRoute.txt"
        )
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.get(url: "\(server.hostURL)/custom-with-query?\(query)") { code, body, headers in
            expectation.fulfill()
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testCustomRoute test fixture\n")
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }
    
    func testCustomRouteWithoutQueryParameters() {
        let route: MockHTTPRoute = .custom(
            method: .get,
            urlPath: "/custom-with-query",
            query: ["item1": "value1", "item2": "value2"],
            requestHeaders: [:],
            responseHeaders: [:],
            code: 200,
            filename: "testCustomRoute.txt"
        )
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 404 response with empty response body")
        
        HTTPClient.get(url: "\(server.hostURL)/custom-with-query") { code, body, headers in
            expectation.fulfill()
            XCTAssertEqual(code, 404)
            XCTAssertEqual(body, "")
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }
    
    func testCustomRouteWithoutAnyAdditionalInfo() {
        let route: MockHTTPRoute = .custom(
            method: .get,
            urlPath: "/custom-with-query",
            query: [:],
            requestHeaders: [:],
            responseHeaders: [:],
            code: 200,
            filename: nil
        )
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with no response body")

        HTTPClient.get(url: "\(server.hostURL)/custom-with-query") { code, body, headers in
            expectation.fulfill()
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "")
        }
        self.waitForExpectations(timeout: timeout, handler: nil)
    }
}

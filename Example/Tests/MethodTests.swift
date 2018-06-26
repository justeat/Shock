//
//  MethodTests.swift
//  Shock
//
//  Created by Jack Newcombe on 29/03/2018.
//

import XCTest
@testable import Shock

class MethodTests: XCTestCase {
    
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

    func testGETRequest() {
        
        let route: MockHTTPRoute = .simple(method: .GET, url: "/simple", code: 200, filename: "testSimpleRoute.txt")
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.get(url: "\(server.hostURL)/simple") { (code, responseBody) in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(responseBody, "testSimpleRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
        
    }
    
    func testPOSTRequest() {
        
        let route: MockHTTPRoute = .simple(method: .POST, url: "/simple", code: 200, filename: "testSimpleRoute.txt")
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.post(url: "\(server.hostURL)/simple") { (code, responseBody) in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(responseBody, "testSimpleRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
        
    }
    
    func testPUTRequest() {
        
        let route: MockHTTPRoute = .simple(method: .PUT, url: "/simple", code: 200, filename: "testSimpleRoute.txt")
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.put(url: "\(server.hostURL)/simple") { (code, responseBody) in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(responseBody, "testSimpleRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
        
    }
    
    func testDELETERequest() {
        
        let route: MockHTTPRoute = .simple(method: .DELETE, url: "/simple", code: 200, filename: "testSimpleRoute.txt")
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.delete(url: "\(server.hostURL)/simple") { (code, responseBody) in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(responseBody, "testSimpleRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
        
    }
    
}

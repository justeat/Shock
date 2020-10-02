//
//  MethodTests.swift
//  Shock
//
//  Created by Jack Newcombe on 27/06/2018.
//  Copyright © 2018 Just Eat. All rights reserved.
//

import XCTest
@testable import Shock

class MethodTests: XCTestCase {
    
    var server: MockServer!
    
    override func setUp() {
        super.setUp()
        server = MockServer(portRange: 9090...9099, bundle: Bundle(for: MethodTests.self))
        server.start()
    }
    
    override func tearDown() {
        server.stop()
        super.tearDown()
    }
    
    func testGETRequest() {
        let route: MockHTTPRoute = .simple(method: .get,
                                           urlPath: "/simple",
                                           code: 200,
                                           filename: "testSimpleRoute.txt")
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.get(url: "\(server.hostURL)/simple") { code, body, headers, error in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testSimpleRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testPOSTRequest() {
        let route: MockHTTPRoute = .simple(method: .post,
                                           urlPath: "/simple",
                                           code: 200,
                                           filename: "testSimpleRoute.txt")
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.post(url: "\(server.hostURL)/simple") { code, body, headers, error in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testSimpleRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testPOSTRequestWithoutFilename() {
        let route: MockHTTPRoute = .simple(method: .post,
                                           urlPath: "/simple",
                                           code: 200,
                                           filename: "")
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.post(url: "\(server.hostURL)/simple") { code, body, headers, error in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testPOSTRequestWithPOSTRequest() {
        let route: MockHTTPRoute = .simple(method: .post,
                                           urlPath: "/simple",
                                           code: 200,
                                           filename: "")
        server.setup(route: route)
        
        let auth: MockHTTPRoute = .simple(method: .post,
                                          urlPath: "/auth",
                                          code: 200,
                                          filename: "testSimpleRoute.txt")
        server.setup(route: auth)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.post(url: "\(server.hostURL)/auth") { code, body, headers, error in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testSimpleRoute test fixture\n")
            HTTPClient.post(url: "\(self.server.hostURL)/simple") { code, body, headers, error in
                XCTAssertEqual(code, 200)
                XCTAssertEqual(body, "")
                expectation.fulfill()
            }
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testPUTRequest() {
        let route: MockHTTPRoute = .simple(method: .put,
                                           urlPath: "/simple",
                                           code: 200,
                                           filename: "testSimpleRoute.txt")
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.put(url: "\(server.hostURL)/simple") { code, body, headers, error in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testSimpleRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testDELETERequest() {
        let route: MockHTTPRoute = .simple(method: .delete,
                                           urlPath: "/simple",
                                           code: 200,
                                           filename: "testSimpleRoute.txt")
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.delete(url: "\(server.hostURL)/simple") { code, body, headers, error in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testSimpleRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
}

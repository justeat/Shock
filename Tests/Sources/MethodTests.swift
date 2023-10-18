//  MethodTests.swift

import XCTest
import Shock

class MethodTests: ShockTestCase {
    
    func testGETRequest() {
        let route: MockHTTPRoute = .simple(method: .get,
                                           urlPath: "/simple",
                                           code: 200,
                                           filename: "testSimpleRoute.txt")
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.get(url: "\(server.hostURL)/simple") { code, body, _, _ in
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
        
        HTTPClient.post(url: "\(server.hostURL)/simple") { code, body, _, _ in
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
        
        HTTPClient.post(url: "\(server.hostURL)/simple") { code, body, _, _ in
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
        
        HTTPClient.post(url: "\(server.hostURL)/auth") { code, body, _, _ in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testSimpleRoute test fixture\n")
            HTTPClient.post(url: "\(self.server.hostURL)/simple") { code, body, _, _ in
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
        
        HTTPClient.put(url: "\(server.hostURL)/simple") { code, body, _, _ in
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
        
        HTTPClient.delete(url: "\(server.hostURL)/simple") { code, body, _, _ in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testSimpleRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
}

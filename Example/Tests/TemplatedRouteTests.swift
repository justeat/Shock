//
//  TemplatedRouteTests.swift
//  Shock
//
//  Created by Jack Newcombe on 01/11/2017.
//

import XCTest
@testable import Shock

class TemplatedRouteTests: XCTestCase {
    
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
    
    func testTemplatedRoute() {
        let route: MockHTTPRoute = .template(method: .GET, urlPath: "/template", code: 200, filename: "testTemplatedRoute", data: [
            "list": [ "Item #1", "Item #2" ],
            "text": "text"
            ])
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with valid generated response body")
        
        HTTPClient.get(url: "\(server.hostURL)/template") { code, responseBody in
            expectation.fulfill()
            let data = responseBody.data(using: .utf8)!
            let dict = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any?]
            let list = dict["list"] as! [String]
            XCTAssertEqual(dict["text"] as! String, "text")
            XCTAssertEqual(list[0], "Item #1")
            XCTAssertEqual(list[1], "Item #2")
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
}

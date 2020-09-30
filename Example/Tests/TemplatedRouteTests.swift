//
//  TemplatedRouteTests.swift
//  Shock
//
//  Created by Jack Newcombe on 27/06/2018.
//  Copyright © 2018 Just Eat. All rights reserved.
//

import XCTest
@testable import Shock

class TemplatedRouteTests: XCTestCase {
    
    var server: MockServer!
    
    override func setUp() {
        super.setUp()
        server = MockServer(portRange: 9090...9099, bundle: Bundle(for: TemplatedRouteTests.self))
        server.start()
    }
    
    override func tearDown() {
        server.stop()
        super.tearDown()
    }
    
    func testTemplatedRoute() {
        let route: MockHTTPRoute = .template(method: .get,
                                             urlPath: "/template",
                                             code: 200,
                                             filename: "testTemplatedRoute",
                                             templateInfo: [
                                                "list": ["Item #1", "Item #2"],
                                                "text": "text"
            ])
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with valid generated response body")
        
        HTTPClient.get(url: "\(server.hostURL)/template") { code, body, headers, error in
            expectation.fulfill()
            let data = body.data(using: .utf8)!
            let dict = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any?]
            let list = dict["list"] as! [String]
            XCTAssertEqual(dict["text"] as! String, "text")
            XCTAssertEqual(list[0], "Item #1")
            XCTAssertEqual(list[1], "Item #2")
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
}

//  TemplatedRouteTests.swift

import XCTest
@testable import Shock

class TemplatedRouteTests: ShockTestCase {
    
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
        
        HTTPClient.get(url: "\(server.hostURL)/template") { _, body, _, _ in
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

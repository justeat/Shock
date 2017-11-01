import UIKit
import XCTest
@testable import Shock

class Tests: XCTestCase {
	
	let server = MockServer(port: 9090, bundle: Bundle(for: Tests.self))
    
    override func setUp() {
        super.setUp()
		server.start()
	}
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
		server.stop()
    }
    
	func testSimpleRoute() {
		
		let route: MockHTTPRoute = .simple(method: .GET, url: "/simple", code: 200, filename: "testSimpleRoute.txt")
		server.setupRoute(route: route)
		
		let expectation = self.expectation(description: "Expect 200 response with response body")
		
		HTTPClient.get(url: "\(server.hostURL)/simple") { (code, responseBody) in
			XCTAssertEqual(code, 200)
			XCTAssertEqual(responseBody, "testSimpleRoute test fixture\n")
			expectation.fulfill()
		}
		self.waitForExpectations(timeout: 2.0, handler: nil)
	}
	
	func testCustomRoute() {
		let route: MockHTTPRoute = .custom(method: .GET, url: "/custom", query: [:], headers: [:], code: 200, filename: "testCustomRoute.txt")
		server.setupRoute(route: route)
	
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
            url: "/custom-with-header",
            query: [:],
            headers: customHeaders,
            code: 200,
            filename: "testCustomRoute.txt"
        )
        server.setupRoute(route: route)
  
        let expectation = self.expectation(description: "Expect 200 response with response body")

        HTTPClient.get(url: "\(server.hostURL)/custom-with-header", headers: customHeaders) { (code, responseBody) in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(responseBody, "testCustomRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testCustomRouteWithQuery() {
        
        let query = "item1=value1&item2=value2"
        
        let route: MockHTTPRoute = .custom(
            method: .GET,
            url: "/custom-with-query",
            query: [ "item1": "value1", "item2": "value2" ],
            headers: [:],
            code: 200,
            filename: "testCustomRoute.txt"
        )
        server.setupRoute(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.get(url: "\(server.hostURL)/custom-with-query?\(query)") { (code, responseBody) in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(responseBody, "testCustomRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }

    
	func testRedirectRoute() {
		
		let route: MockHTTPRoute = .collection(routes: [
			.redirect(url: "/redirect", destination: "/destination"),
			.simple(method: .GET, url: "/destination", code: 200, filename: "testRedirectRoute.txt")
		])
		server.setupRoute(route: route)
		
		let expectation = self.expectation(description: "Expect 200 response with response body after redirect")
		
		HTTPClient.get(url: "\(server.hostURL)/redirect") { (code, responseBody) in
			XCTAssertEqual(code, 200)
			XCTAssertEqual(responseBody, "testRedirectRoute test fixture\n")
			expectation.fulfill()
		}
		self.waitForExpectations(timeout: 2.0, handler: nil)
	}
	
	func testTemplatedRoute() {
		let route: MockHTTPRoute = .template(method: .GET, url: "/template", code: 200, filename: "testTemplatedRoute", data: [
			"list": [ "Item #1", "Item #2" ],
			"text": "text"
		])
		server.setupRoute(route: route)
		
		let expectation = self.expectation(description: "Expect 200 response with valid generated response body")
		
		HTTPClient.get(url: "\(server.hostURL)/template") { code, responseBody in
			let data = responseBody.data(using: .utf8)!
			let dict = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any?]
			let list = dict["list"] as! [String]
			XCTAssertEqual(dict["text"] as! String, "text")
			XCTAssertEqual(list[0], "Item #1")
			XCTAssertEqual(list[1], "Item #2")
			expectation.fulfill()
		}
		self.waitForExpectations(timeout: 2.0, handler: nil)
	}
	
	func testRouteProperties() {
		
		let emptyRoute: MockHTTPRoute = .collection(routes: [])
		XCTAssertNil(emptyRoute.url)
		XCTAssertNil(emptyRoute.method)
		
	}
    
}

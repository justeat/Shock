//
//  ClosureMiddlewareTests.swift
//  Shock_Tests
//
//  Created by Jack Newcombe on 07/10/2020.
//  Copyright © 2018 Just Eat. All rights reserved.
//

import XCTest
import Shock

class ClosureMiddlewareTests: ShockTestCase {

    func testSimpleClosureMiddleware() {
        
        let expectedResponseBody = "Test Response Body"
        let expectedHeaders = [ "X-Test-Header": "Test" ]
        let expectedStatusCode = 200
        
        let middleware = ClosureMiddleware { request, response, next in
            response.statusCode = expectedStatusCode
            response.headers = expectedHeaders
            response.responseBody = expectedResponseBody.data(using: .utf8)
            next()
        }
        server.add(middleware: middleware)
        
        let getExpectation = expectation(description: "GET request succeeeds")
        HTTPClient.get(url: "\(server.hostURL)/") { code, body, headers, error in
            XCTAssertNil(error)
            XCTAssertEqual(code, expectedStatusCode)
            expectedHeaders.forEach {
                XCTAssertEqual(headers[$0.key], $0.value)
            }
            XCTAssertEqual(body, expectedResponseBody)
            getExpectation.fulfill()
        }

        let postExpectation = expectation(description: "GET request succeeeds")
        HTTPClient.post(url: "\(server.hostURL)/") { code, body, headers, error in
            XCTAssertNil(error)
            XCTAssertEqual(code, expectedStatusCode)
            expectedHeaders.forEach {
                XCTAssertEqual(headers[$0.key], $0.value)
            }
            XCTAssertEqual(body, expectedResponseBody)
            postExpectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout)
    }
}

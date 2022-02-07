//
//  RouteTests.swift
//  Shock
//
//  Created by Jack Newcombe on 27/06/2018.
//  Copyright © 2018 Just Eat. All rights reserved.
//

import XCTest
import Shock

class RouteTests: ShockTestCase {
    
    func testSimpleRoute() {
        let route: MockHTTPRoute = .simple(method: .get, urlPath: "/simple", code: 200, filename: "testSimpleRoute.txt")
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
         
        HTTPClient.get(url: "\(server.hostURL)/simple") { code, body, headers, error in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testSimpleRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testSimpleRouteWithVariables() {
        let route: MockHTTPRoute = .simple(method: .get, urlPath: "/simple/:foo", code: 200, filename: "testSimpleRouteWithVariables.txt")
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.get(url: "\(server.hostURL)/simple/1") { code, body, headers, error in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testSimpleRoute (with variables) test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testSimpleRouteWithAndWithoutVariables() {
        let withoutRoute: MockHTTPRoute = .simple(method: .get, urlPath: "/simple/withoutvariables", code: 200, filename: "testSimpleRoute.txt")
        let withRoute: MockHTTPRoute = .simple(method: .get, urlPath: "/simple/withvariables/:foo", code: 200, filename: "testSimpleRouteWithVariables.txt")
        server.setup(route: .collection(routes: [withRoute, withoutRoute]))
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.get(url: "\(server.hostURL)/simple/withvariables/1") { code, body, headers, error in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testSimpleRoute (with variables) test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testSimpleRouteWithEmptyURLPath() {
        let withoutRoute: MockHTTPRoute = .simple(method: .get, urlPath: "", code: 200, filename: "testSimpleRoute.txt")
        let withRoute: MockHTTPRoute = .simple(method: .get, urlPath: "/simple/withvariables/:foo", code: 200, filename: "testSimpleRouteWithVariables.txt")
        server.setup(route: .collection(routes: [withRoute, withoutRoute]))
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.get(url: "\(server.hostURL)/simple/withvariables/1") { code, body, headers, error in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testSimpleRoute (with variables) test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testSimpleRouteWithEmptyURLPathAlternate() {
        let withoutRoute: MockHTTPRoute = .simple(method: .get, urlPath: "/simple/withoutvariables", code: 200, filename: "testSimpleRoute.txt")
        let withRoute: MockHTTPRoute = .simple(method: .get, urlPath: "", code: 200, filename: "testSimpleRouteWithVariables.txt")
        server.setup(route: .collection(routes: [withRoute, withoutRoute]))
        
        let expectation = self.expectation(description: "Expect 200 response with response body")
        
        HTTPClient.get(url: "\(server.hostURL)/simple/withoutvariables") { code, body, headers, error in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testSimpleRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testRedirectRoute() {
        let route: MockHTTPRoute = .collection(routes: [
            .redirect(urlPath: "/redirect", destination: "/destination"),
            .simple(method: .get, urlPath: "/destination", code: 200, filename: "testRedirectRoute.txt")
            ])
        server.setup(route: route)
        
        let expectation = self.expectation(description: "Expect 200 response with response body after redirect")
        
        HTTPClient.get(url: "\(server.hostURL)/redirect") { code, body, headers, error in
            XCTAssertEqual(code, 200)
            XCTAssertEqual(body, "testRedirectRoute test fixture\n")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testRouteProperties() {
        let emptyRoute: MockHTTPRoute = .collection(routes: [])
        XCTAssertNil(emptyRoute.urlPath)
        XCTAssertNil(emptyRoute.method)
    }
    
    func testTimeoutRoute() {
        let route: MockHTTPRoute = .timeout(method: .get, urlPath: "/timeouttest", timeoutInSeconds: 2)
        server.setup(route: route)
        
        let expectation = self.expectation(description: "This expectation should NOT be fulfilled")
        
        HTTPClient.get(url: "\(server.hostURL)/timeouttest", timeout: 2) { _,_,_,error in
            XCTAssertNotNil(error, "Request should have errored")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.5, handler: nil)
    }
    
    func testSimpleRouteEquivalence() {
        var route1 = MockHTTPRoute.simple(method: .get, urlPath: "/restaurants/bypostcode/:postcode", code: 200, filename: nil)
        var route2 = MockHTTPRoute.simple(method: .get, urlPath: "/restaurants/bypostcode/:postcode", code: 200, filename: nil)
        XCTAssertEqual(route1, route2, "Simple gets should be equal")
        route1 = MockHTTPRoute.simple(method: .get, urlPath: "/restaurants/bypostcode/{postcode}", code: 200, filename: nil)
        route2 = MockHTTPRoute.simple(method: .get, urlPath: "/restaurants/bypostcode/{postcode}", code: 200, filename: nil)
        XCTAssertEqual(route1, route2, "Simple gets should be equal")
        route1 = MockHTTPRoute.simple(method: .get, urlPath: "/restaurants/bypostcode/:postcode", code: 200, filename: nil)
        route2 = MockHTTPRoute.simple(method: .get, urlPath: "/restaurants/bypostcode/AR511AA", code: 200, filename: nil)
        XCTAssertEqual(route1, route2, "Simple gets should be equal")
        route1 = MockHTTPRoute.simple(method: .get, urlPath: "/restaurants/bypostcode/{postcode}", code: 200, filename: nil)
        route2 = MockHTTPRoute.simple(method: .get, urlPath: "/restaurants/bypostcode/AR511AA", code: 200, filename: nil)
        XCTAssertEqual(route1, route2, "Simple gets should be equal")
        route1 = MockHTTPRoute.simple(method: .get, urlPath: "/restaurants/bypostcode/:postcode", code: 200, filename: nil)
        route2 = MockHTTPRoute.simple(method: .get, urlPath: "restaurants/:id/reviews", code: 200, filename: nil)
        XCTAssertNotEqual(route1, route2, "Paths are different, should not be equal")
    }
    
    func testSimpleRouteWithVariablesEquivalence() {
        var route1 = MockHTTPRoute.simple(method: .get, urlPath: "foo/bar", code: 200, filename: nil)
        var route2 = MockHTTPRoute.simple(method: .get, urlPath: "foo/bar", code: 200, filename: nil)
        XCTAssertEqual(route1, route2, "Simple gets should be equal")
        route1 = MockHTTPRoute.simple(method: .get, urlPath: "foo/bar", code: 200, filename: nil)
        route2 = MockHTTPRoute.simple(method: .get, urlPath: "foo/bar", code: 404, filename: nil)
        XCTAssertEqual(route1, route2, "Codes are different, should not affect equality")
        route1 = MockHTTPRoute.simple(method: .get, urlPath: "foo/bar", code: 200, filename: nil)
        route2 = MockHTTPRoute.simple(method: .get, urlPath: "bar/foo", code: 200, filename: nil)
        XCTAssertNotEqual(route1, route2, "Paths are different, should not be equal")
        route1 = MockHTTPRoute.simple(method: .get, urlPath: "foo/bar", code: 200, filename: nil)
        route2 = MockHTTPRoute.simple(method: .post, urlPath: "foo/bar", code: 200, filename: nil)
        XCTAssertNotEqual(route1, route2, "Methods are different, should not be equal")
    }
    
    func testCustomRouteEquivalence() {
        var route1 = MockHTTPRoute.custom(method: .get, urlPath: "foo/bar", query: ["query":"value"],
                                          requestHeaders: ["HTTPHeader":"false"], responseHeaders: ["HTTPHeader":"true"], code: 200, filename: nil)
        var route2 = MockHTTPRoute.custom(method: .get, urlPath: "foo/bar", query: ["query":"value"],
                                          requestHeaders: ["HTTPHeader":"false"], responseHeaders: ["HTTPHeader":"true"], code: 200, filename: nil)
        XCTAssertEqual(route1, route2, "Custom routes should be equal")
        route1 = MockHTTPRoute.custom(method: .get, urlPath: "foo/bar", query: ["query":"value"],
                                      requestHeaders: ["HTTPHeader":"false"], responseHeaders: ["HTTPHeader":"true"], code: 200, filename: nil)
        route2 = MockHTTPRoute.custom(method: .get, urlPath: "foo/bar", query: ["query":"value"],
                                      requestHeaders: ["HTTPHeader":"false"], responseHeaders: ["HTTPHeader":"true"], code: 404, filename: nil)
        XCTAssertEqual(route1, route2, "Codes are different, should not affect equality")
        route1 = MockHTTPRoute.custom(method: .get, urlPath: "foo/bar", query: ["query":"value"],
                                      requestHeaders: ["HTTPHeader":"false"], responseHeaders: ["HTTPHeader":"true"], code: 200, filename: nil)
        route2 = MockHTTPRoute.custom(method: .get, urlPath: "foo/bar", query: ["query":"value2"],
                                      requestHeaders: ["HTTPHeader":"false"], responseHeaders: ["HTTPHeader":"true"], code: 200, filename: nil)
        XCTAssertNotEqual(route1, route2, "Queries are different, should not be equal")
        route1 = MockHTTPRoute.custom(method: .get, urlPath: "foo/bar", query: ["query":"value"],
                                      requestHeaders: ["HTTPHeader":"false"], responseHeaders: ["HTTPHeader":"true"], code: 200, filename: nil)
        route2 = MockHTTPRoute.custom(method: .get, urlPath: "foo/bar", query: ["query":"value"],
                                      requestHeaders: ["HTTPHeader":"true"], responseHeaders: ["HTTPHeader":"true"], code: 200, filename: nil)
        XCTAssertNotEqual(route1, route2, "Request headers are different, should not be equal")
        route1 = MockHTTPRoute.custom(method: .get, urlPath: "foo/bar", query: ["query":"value"],
                                      requestHeaders: ["HTTPHeader":"false"], responseHeaders: ["HTTPHeader":"true"], code: 200, filename: nil)
        route2 = MockHTTPRoute.custom(method: .get, urlPath: "bar/foo", query: ["query":"value"],
                                      requestHeaders: ["HTTPHeader":"false"], responseHeaders: ["HTTPHeader":"true"], code: 200, filename: nil)
        XCTAssertNotEqual(route1, route2, "Paths are different, should not be equal")
        route1 = MockHTTPRoute.custom(method: .get, urlPath: "foo/bar", query: ["query":"value"],
                                      requestHeaders: ["HTTPHeader":"false"], responseHeaders: ["HTTPHeader":"true"], code: 200, filename: nil)
        route2 = MockHTTPRoute.custom(method: .post, urlPath: "foo/bar", query: ["query":"value"],
                                      requestHeaders: ["HTTPHeader":"false"], responseHeaders: ["HTTPHeader":"true"], code: 200, filename: nil)
        XCTAssertNotEqual(route1, route2, "Methods are different, should not be equal")
    }
    
    func testTemplateRouteEquivalence() {
        var route1 = MockHTTPRoute.template(method: .get, urlPath: "foo/bar", code: 200, filename: nil, templateInfo: ["Value" : 1])
        var route2 = MockHTTPRoute.template(method: .get, urlPath: "foo/bar", code: 200, filename: nil, templateInfo: ["Value" : 1])
        XCTAssertEqual(route1, route2, "Template routes should be equal")
        route1 = MockHTTPRoute.template(method: .get, urlPath: "foo/bar", code: 200, filename: nil, templateInfo: ["Value" : 1])
        route2 = MockHTTPRoute.template(method: .get, urlPath: "foo/bar", code: 200, filename: nil, templateInfo: ["Value" : 2])
        XCTAssertEqual(route1, route2, "Templates are different, should not affect equality")
        route1 = MockHTTPRoute.template(method: .get, urlPath: "foo/bar", code: 200, filename: nil, templateInfo: ["Value" : 1])
        route2 = MockHTTPRoute.template(method: .get, urlPath: "foo/bar", code: 404, filename: nil, templateInfo: ["Value" : 1])
        XCTAssertEqual(route1, route2, "Codes are different, should not affect equality")
        route1 = MockHTTPRoute.template(method: .get, urlPath: "foo/bar", code: 200, filename: nil, templateInfo: ["Value" : 1])
        route2 = MockHTTPRoute.template(method: .get, urlPath: "bar/foo", code: 200, filename: nil, templateInfo: ["Value" : 1])
        XCTAssertNotEqual(route1, route2, "Paths are different, should not be equal")
        route1 = MockHTTPRoute.template(method: .get, urlPath: "foo/bar", code: 200, filename: nil, templateInfo: ["Value" : 1])
        route2 = MockHTTPRoute.template(method: .post, urlPath: "foo/bar", code: 200, filename: nil, templateInfo: ["Value" : 1])
        XCTAssertNotEqual(route1, route2, "Methods are different, should not be equal")
    }
    
    func testRedirectRouteEquivalence() {
        var route1 = MockHTTPRoute.redirect(urlPath: "foo/bar", destination: "bar/foo")
        var route2 = MockHTTPRoute.redirect(urlPath: "foo/bar", destination: "bar/foo")
        XCTAssertEqual(route1, route2, "Redirect routes should be equal")
        route1 = MockHTTPRoute.redirect(urlPath: "foo/bar", destination: "bar/foo")
        route2 = MockHTTPRoute.redirect(urlPath: "bar/foo", destination: "bar/foo")
        XCTAssertNotEqual(route1, route2, "Paths are different, should not be equal")
        route1 = MockHTTPRoute.redirect(urlPath: "foo/bar", destination: "bar/foo")
        route2 = MockHTTPRoute.redirect(urlPath: "foo/bar", destination: "foo/bar")
        XCTAssertEqual(route1, route2, "Destinations are different, should not affect equality")
    }
    
    func testTimeoutRouteEquivalence() {
        var route1 = MockHTTPRoute.timeout(method: .get, urlPath: "foo/bar", timeoutInSeconds: 1)
        var route2 = MockHTTPRoute.timeout(method: .get, urlPath: "foo/bar", timeoutInSeconds: 1)
        XCTAssertEqual(route1, route2, "Timeout routes should be equal")
        route1 = MockHTTPRoute.timeout(method: .get, urlPath: "foo/bar", timeoutInSeconds: 1)
        route2 = MockHTTPRoute.timeout(method: .get, urlPath: "foo/bar", timeoutInSeconds: 2)
        XCTAssertEqual(route1, route2, "Timeouts are different, should not affect equality")
        route1 = MockHTTPRoute.timeout(method: .get, urlPath: "foo/bar", timeoutInSeconds: 1)
        route2 = MockHTTPRoute.timeout(method: .get, urlPath: "bar/foo", timeoutInSeconds: 1)
        XCTAssertNotEqual(route1, route2, "Paths are different, should not be equal")
        route1 = MockHTTPRoute.timeout(method: .get, urlPath: "foo/bar", timeoutInSeconds: 1)
        route2 = MockHTTPRoute.timeout(method: .post, urlPath: "foo/bar", timeoutInSeconds: 1)
        XCTAssertNotEqual(route1, route2, "Methods are different, should not be equal")
    }
    
    func testCollectionRouteEquivalence() {
        var route1 = MockHTTPRoute.collection(routes: [
            .simple(method: .get, urlPath: "foo/bar", code: 200, filename: nil)
        ])
        var route2 = MockHTTPRoute.collection(routes: [
            .simple(method: .get, urlPath: "foo/bar", code: 200, filename: nil)
        ])
        XCTAssertEqual(route1, route2, "Collection routes should be equal")
        route1 = MockHTTPRoute.collection(routes: [
            .simple(method: .get, urlPath: "foo/bar", code: 200, filename: nil)
        ])
        route2 = MockHTTPRoute.collection(routes: [
            .simple(method: .get, urlPath: "foo/bar", code: 404, filename: nil)
        ])
        XCTAssertEqual(route1, route2, "Codes are different, should not affect equality")
        route1 = MockHTTPRoute.collection(routes: [
            .simple(method: .get, urlPath: "foo/bar", code: 200, filename: nil)
        ])
        route2 = MockHTTPRoute.collection(routes: [
            .simple(method: .get, urlPath: "bar/foo", code: 200, filename: nil)
        ])
        XCTAssertNotEqual(route1, route2, "Paths are different, should not be equal")
    }
}

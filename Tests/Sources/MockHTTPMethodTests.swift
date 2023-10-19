//  MockHTTPMethodTests.swift

import XCTest
@testable import Shock

class MockHTTPMethodTests: XCTestCase {
    
    let simpleMock = """
    {
        "type": "simple",
        "method": "GET",
        "urlPath": "/my/api/endpoint",
        "code": 200,
        "filename" : "my-test-data.json"
    }
    """.data(using: .utf8) ?? Data()

    func testDecodeSimpleMockHTTPRoute() throws {
        let decoder = JSONDecoder()
        let route = try decoder.decode(MockHTTPRoute.self, from: simpleMock)
        switch route {
        case .simple(method: let method, urlPath: let urlPath, code: let code, filename: let filename):
            XCTAssertEqual(method, .get)
            XCTAssertEqual(urlPath, "/my/api/endpoint")
            XCTAssertEqual(code, 200)
            XCTAssertEqual(filename, "my-test-data.json")
        default:
            XCTFail("Unable to decode")
        }
    }
    
    func testEncodeSimpleMockHTTPRoute() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let route: MockHTTPRoute = .simple(method: .get, urlPath: "/my/api/endpoint", code: 200, filename: "my-test-data.json")
        let data = try encoder.encode(route)
        let string = try XCTUnwrap(String(data: data, encoding: .utf8))
        let expectedValue = """
        {"code":200,"filename":"my-test-data.json","method":"GET","type":"simple","urlPath":"/my/api/endpoint"}
        """
        XCTAssertEqual(string, expectedValue)
    }
    
    let customMock = """
    {
        "type": "custom",
        "method": "GET",
        "urlPath": "/my/api/endpoint",
        "query": {
            "queryKey": "queryValue"
        },
        "requestHeaders": {
            "X-Custom-Header": "custom-header-value"
        },
        "responseHeaders": {
            "Content-Type": "application/json"
        },
        "code": 200,
        "filename": "my-test-data.json"
    }
    """.data(using: .utf8) ?? Data()
    
    func testDecodeCustomMockHTTPRoute() throws {
        let decoder = JSONDecoder()
        let route = try decoder.decode(MockHTTPRoute.self, from: customMock)
        switch route {
        case .custom(method: let method,
                     urlPath: let urlPath,
                     query: let query,
                     requestHeaders: let requestHeaders,
                     responseHeaders: let responseHeaders,
                     code: let code,
                     filename: let filename):
            XCTAssertEqual(method, .get)
            XCTAssertEqual(urlPath, "/my/api/endpoint")
            XCTAssertEqual(query["queryKey"], "queryValue")
            XCTAssertEqual(requestHeaders["X-Custom-Header"], "custom-header-value")
            XCTAssertEqual(responseHeaders["Content-Type"], "application/json")
            XCTAssertEqual(code, 200)
            XCTAssertEqual(filename, "my-test-data.json")
        default:
            XCTFail("Unable to decode")
        }
    }
    
    func testEncodeCustomMockHTTPRoute() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let route: MockHTTPRoute = .custom(method: .get,
                                           urlPath: "/my/api/endpoint",
                                           query: ["queryKey": "custom-header-value"],
                                           requestHeaders: ["X-Custom-Header": "custom-header-value"],
                                           responseHeaders: ["Content-Type": "application/json"],
                                           code: 200,
                                           filename: "my-test-data.json")
        let data = try encoder.encode(route)
        let string = try XCTUnwrap(String(data: data, encoding: .utf8))
        let expectedValue = """
        {"code":200,"filename":"my-test-data.json","method":"GET","query":{"queryKey":"custom-header-value"},"requestHeaders":{"X-Custom-Header":"custom-header-value"},"responseHeaders":{"Content-Type":"application/json"},"type":"custom","urlPath":"/my/api/endpoint"}
        """
        XCTAssertEqual(string, expectedValue)
    }
    
    let templateMock = """
    {
        "type": "template",
        "method": "GET",
        "urlPath": "/template",
        "code": 200,
        "filename": "my-templated-data.json",
        "templateInfo": {
            "list": ["Item #1", "Item #2"],
            "text": "text",
            "bool": false,
            "int": 3,
            "double": 3.5,
            "dictionary": {
                "key": "value"
            },
            "empty": null
        }
    }
    """.data(using: .utf8) ?? Data()

    func testDecodeTemplateMockHTTPRoute() throws {
        let decoder = JSONDecoder()
        let route = try decoder.decode(MockHTTPRoute.self, from: templateMock)
        switch route {
        case .template(method: let method,
                       urlPath: let urlPath,
                       code: let code,
                       filename: let filename,
                       templateInfo: let templateInfo):
            XCTAssertEqual(method, .get)
            XCTAssertEqual(urlPath, "/template")
            XCTAssertEqual(code, 200)
            let data = try XCTUnwrap(templateInfo as? [String: TemplateParameter])
            XCTAssertEqual(data.count, 7)
            XCTAssertEqual(data["list"]?.array?.count, 2)
            XCTAssertEqual(data["text"]?.string, "text")
            XCTAssertEqual(data["bool"]?.bool, false)
            XCTAssertEqual(data["double"]?.double, 3.5)
            XCTAssertEqual(data["int"]?.int, 3)
            XCTAssertEqual(data["dictionary"]?.dictionary?.count, 1)
            XCTAssertNil(data["empty"]?.value)
            XCTAssertEqual(filename, "my-templated-data.json")
        default:
            XCTFail("Unable to decode")
        }
    }
    
    func testEncodeTemplateMockHTTPRoute() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let route: MockHTTPRoute = .template(method: .get,
                                             urlPath: "/template",
                                             code: 200,
                                             filename: "my-templated-data.json",
                                             templateInfo: ["list": ["Item #1", "Item #2"],
                                                            "text": "text",
                                                            "bool": false,
                                                            "int": 3,
                                                            "double": 3.5,
                                                            "dictionary": [
                                                                "key": "value"
                                                            ],
                                                            "empty": NSNull()])
        let data = try encoder.encode(route)
        let string = try XCTUnwrap(String(data: data, encoding: .utf8))
        let expectedValue = """
        {"code":200,"filename":"my-templated-data.json","method":"GET","templateInfo":{"bool":false,"dictionary":{"key":"value"},"double":3.5,"empty":null,"int":3,"list":["Item #1","Item #2"],"text":"text"},"type":"template","urlPath":"/template"}
        """
        XCTAssertEqual(string, expectedValue)
    }
    
    let collectionMock = """
    {
        "type": "collection",
        "routes": [
            {
                "type": "simple",
                "method": "GET",
                "urlPath": "/my/api/endpoint",
                "code": 200,
                "filename" : "my-test-data.json"
            },
            {
                "type": "simple",
                "method": "GET",
                "urlPath": "/my/api/endpoint2",
                "code": 200,
                "filename" : "my-test-data2.json"
            }
        ]
    }
    """.data(using: .utf8) ?? Data()
    
    func testDecodeCollectionMockHTTPRoute() throws {
        let decoder = JSONDecoder()
        let route = try decoder.decode(MockHTTPRoute.self, from: collectionMock)
        switch route {
        case .collection(routes: let routes):
            XCTAssertEqual(routes.count, 2)
        default:
            XCTFail("Unable to decode")
        }
    }
    
    func testEncodeCollectionMockHTTPRoute() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let route: MockHTTPRoute = .collection(routes: [
            .simple(method: .get, urlPath: "/my/api/endpoint", code: 200, filename: "my-test-data.json"),
            .simple(method: .get, urlPath: "/my/api/endpoint2", code: 200, filename: "my-test-data2.json")
        ])
        let data = try encoder.encode(route)
        let string = try XCTUnwrap(String(data: data, encoding: .utf8))
        let expectedValue = """
        {"routes":[{"code":200,"filename":"my-test-data.json","method":"GET","type":"simple","urlPath":"/my/api/endpoint"},{"code":200,"filename":"my-test-data2.json","method":"GET","type":"simple","urlPath":"/my/api/endpoint2"}],"type":"collection"}
        """
        XCTAssertEqual(string, expectedValue)
    }
    
    let timeoutMock = """
    {
        "type": "timeout",
        "method": "GET",
        "urlPath": "/timeouttest",
        "timeoutInSeconds": 5
    }
    """.data(using: .utf8) ?? Data()
    
    func testDecodeTimeoutMockHTTPRoute() throws {
        let decoder = JSONDecoder()
        let route = try decoder.decode(MockHTTPRoute.self, from: timeoutMock)
        switch route {
        case .timeout(method: let method, urlPath: let urlPath, timeoutInSeconds: let timeoutInSeconds):
            XCTAssertEqual(method, .get)
            XCTAssertEqual(urlPath, "/timeouttest")
            XCTAssertEqual(timeoutInSeconds, 5)
        default:
            XCTFail("Unable to decode")
        }
    }
    
    func testEncodeTimeoutMockHTTPRoute() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let route: MockHTTPRoute = .timeout(method: .get, urlPath: "/timeouttest", timeoutInSeconds: 5)
        let data = try encoder.encode(route)
        let string = try XCTUnwrap(String(data: data, encoding: .utf8))
        let expectedValue = """
        {"method":"GET","timeoutInSeconds":5,"type":"timeout","urlPath":"/timeouttest"}
        """
        XCTAssertEqual(string, expectedValue)
    }
    
    let redirectMock = """
    {
        "type": "redirect",
        "urlPath": "/source",
        "destination": "/destination"
    }
    """.data(using: .utf8) ?? Data()
    
    func testDecodeRedirectMockHTTPRoute() throws {
        let decoder = JSONDecoder()
        let route = try decoder.decode(MockHTTPRoute.self, from: redirectMock)
        switch route {
        case .redirect(urlPath: let urlPath, destination: let destination):
            XCTAssertEqual(urlPath, "/source")
            XCTAssertEqual(destination, "/destination")
        default:
            XCTFail("Unable to decode")
        }
    }
    
    func testEncodeRedirectMockHTTPRoute() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let route: MockHTTPRoute = .redirect(urlPath: "/source", destination: "/destination")
        let data = try encoder.encode(route)
        let string = try XCTUnwrap(String(data: data, encoding: .utf8))
        let expectedValue = """
        {"destination":"/destination","type":"redirect","urlPath":"/source"}
        """
        XCTAssertEqual(string, expectedValue)
    }
}

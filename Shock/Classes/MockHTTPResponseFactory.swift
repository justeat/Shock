//
//  HTTPResponseFactory.swift
//  Shock
//
//  Created by Jack Newcombe on 27/06/2018.
//  Copyright © 2018 Just Eat. All rights reserved.
//

import Foundation
#if canImport(GRMustache)
import GRMustache
fileprivate typealias Template = GRMustacheTemplate
#elseif canImport(Mustache)
import Mustache
#endif


class MockHTTPResponseFactory {

    private let bundle: Bundle

    init(bundle: Bundle = Bundle.main) {
        self.bundle = bundle
    }

    func makeResponse(urlPath: String, jsonFilename: String?, method: String = "GET", code: Int = 200, headers: [String: String] = [:]) -> MockHttpResponse {
        return MockHttpResponse.raw(code, urlPath, headers) { writer in
            guard let jsonFilename = jsonFilename,let responseBody = self.loadJson(named: jsonFilename) else { return }
            try! writer.write(responseBody.data(using: String.Encoding.utf8)!)
        }
    }

    func makeResponse(urlPath: String, templateFilename: String?, data: [String: Any?]? = nil, method: String = "GET", code: Int = 200, headers: [String: String] = [:]) -> MockHttpResponse {

        return MockHttpResponse.raw(code, urlPath, headers) { writer in
            guard let templateFilename = templateFilename, let data = data else { return }
            let template = self.loadTemplate(withFileName: templateFilename)
            let responseBody: String = self.render(withTemplate: template, data: data)
            try! writer.write(responseBody.data(using: String.Encoding.utf8)!)
        }
    }

    func makeResponse(urlPath: String, destination: String) -> MockHttpResponse {
        return MockHttpResponse.movedPermanently(destination)
    }

    func makeResponse(urlPath: String, method: String = "GET", timeout: Int = 120) -> MockHttpResponse {
        return MockHttpResponse.raw(200, urlPath, [:]) { writer in
            // don't write anything, instead wait
            let semaphore = DispatchSemaphore(value: 0)
            _ = semaphore.wait(timeout: DispatchTime.now() + .seconds(timeout))
        }
    }

    // MARK: Utilities

    private func loadTemplate(withFileName templateFilename: String) -> Template {
        #if canImport(GRMustache)
        return try! Template(fromResource: templateFilename, bundle: bundle)
        #elseif canImport(Mustache)
        return try! Template(named: templateFilename, bundle: bundle)
        #endif
    }

    private func render(withTemplate template: Template, data: Any?) -> String {
        #if canImport(GRMustache)
         return try! template.renderObject(data)
         #elseif canImport(Mustache)
         return try! template.render(data)
         #endif
    }

    private func loadJson(named name: String) -> String? {

        let components = name.components(separatedBy: ".")
        let url: URL

        switch components.count {
        case 0:
            url = URL(string: name)!
        case 1:
            url = bundle.url(forResource: components[0], withExtension: "json")!
        default:
            var components = components
            let ext = components.removeLast()
            url = bundle.url(forResource: components.joined(separator: "."), withExtension: ext)!
        }

        return try? String(contentsOf: url)
    }
}

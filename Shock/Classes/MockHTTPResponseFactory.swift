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
typealias Template = GRMustacheTemplate
#elseif canImport(Mustache)
import Mustache
#endif

class ResponseFactory {
    
    class TemplateHelper {
        
        let bundle: Bundle
        
        init(bundle: Bundle) {
            self.bundle = bundle
        }
        
        func load(withFileName templateFilename: String) -> Template {
            #if canImport(GRMustache)
            return try! Template(fromResource: templateFilename, bundle: bundle)
            #elseif canImport(Mustache)
            return try! Template(named: templateFilename, bundle: bundle)
            #endif
        }

        func render(withTemplate template: Template, data: Any?) -> String {
            #if canImport(GRMustache)
             return try! template.renderObject(data)
             #elseif canImport(Mustache)
             return try! template.render(data)
             #endif
        }
    }
    
    let bundle: Bundle
    
    init(bundle: Bundle) {
        self.bundle = bundle
    }
    
    func response(withTemplateFileName templateFileName: String, data: Any) -> Data? {
        let templateHelper = TemplateHelper(bundle: bundle)
        let template = templateHelper.load(withFileName: templateFileName)
        let responseData: String = templateHelper.render(withTemplate: template, data: data)
        return responseData.data(using: .utf8)
    }
    
    func response(fromFileNamed name: String) -> Data? {

        let components = name.components(separatedBy: ".")
        let _url: URL?

        switch components.count {
        case 0:
            _url = URL(string: name)
        case 1:
            _url = bundle.url(forResource: components[0], withExtension: "json")
        default:
            var components = components
            let ext = components.removeLast()
            _url = bundle.url(forResource: components.joined(separator: "."), withExtension: ext)!
        }

        guard let url = _url else { return nil }
        return try? Data(contentsOf: url)
    }
    
}

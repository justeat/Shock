//  MockHTTPRoute+Codable.swift

import Foundation

extension MockHTTPMethod: Codable { }

extension MockHTTPRoute: Codable {
    
    enum CodingKeys: String, CodingKey {
        case type
        case method
        case urlPath
        case code
        case filename
        case query
        case requestHeaders
        case responseHeaders
        case templateInfo
        case destination
        case routes
        case timeoutInSeconds
    }
    
    enum MockHTTPRouteType: String, CodingKey, Codable {
        case simple
        case custom
        case template
        case redirect
        case collection
        case timeout
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MockHTTPRouteType.self, forKey: .type)
        switch type {
        case .simple:
            let method = try container.decode(MockHTTPMethod.self, forKey: .method)
            let urlPath = try container.decode(String.self, forKey: .urlPath)
            let code = try container.decode(Int.self, forKey: .code)
            let filename = try? container.decode(String.self, forKey: .filename)
            self = .simple(method: method, urlPath: urlPath, code: code, filename: filename)
        case .custom:
            let method = try container.decode(MockHTTPMethod.self, forKey: .method)
            let urlPath = try container.decode(String.self, forKey: .urlPath)
            let query = try container.decode([String: String].self, forKey: .query)
            let requestHeaders = try container.decode([String: String].self, forKey: .requestHeaders)
            let responseHeaders = try container.decode([String: String].self, forKey: .responseHeaders)
            let code = try container.decode(Int.self, forKey: .code)
            let filename = try? container.decode(String.self, forKey: .filename)
            self = .custom(method: method,
                           urlPath: urlPath,
                           query: query,
                           requestHeaders: requestHeaders,
                           responseHeaders: responseHeaders,
                           code: code,
                           filename: filename)
        case .template:
            let method = try container.decode(MockHTTPMethod.self, forKey: .method)
            let urlPath = try container.decode(String.self, forKey: .urlPath)
            let code = try container.decode(Int.self, forKey: .code)
            let filename = try? container.decode(String.self, forKey: .filename)
            let templateInfo = try container.decode([String: TemplateParameter].self, forKey: .templateInfo)
            self = .template(method: method,
                             urlPath: urlPath,
                             code: code,
                             filename: filename,
                             templateInfo: templateInfo)
        case .redirect:
            let urlPath = try container.decode(String.self, forKey: .urlPath)
            let destination = try container.decode(String.self, forKey: .destination)
            self = .redirect(urlPath: urlPath, destination: destination)
        case .timeout:
            let method = try container.decode(MockHTTPMethod.self, forKey: .method)
            let urlPath = try container.decode(String.self, forKey: .urlPath)
            let timeoutInSeconds = try container.decode(Int.self, forKey: .timeoutInSeconds)
            self = .timeout(method: method, urlPath: urlPath, timeoutInSeconds: timeoutInSeconds)
        case .collection:
            let routes = try container.decode([MockHTTPRoute].self, forKey: .routes)
            self = .collection(routes: routes)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .simple(method: let method, urlPath: let urlPath, code: let code, filename: let filename):
            try container.encode(MockHTTPRouteType.simple.rawValue, forKey: .type)
            try container.encode(method, forKey: .method)
            try container.encode(urlPath, forKey: .urlPath)
            try container.encode(code, forKey: .code)
            try container.encode(filename, forKey: .filename)
        case .custom(method: let method,
                     urlPath: let urlPath,
                     query: let query,
                     requestHeaders: let requestHeaders,
                     responseHeaders: let responseHeaders,
                     code: let code,
                     filename: let filename):
            try container.encode(MockHTTPRouteType.custom.rawValue, forKey: .type)
            try container.encode(method, forKey: .method)
            try container.encode(urlPath, forKey: .urlPath)
            try container.encode(query, forKey: .query)
            try container.encode(requestHeaders, forKey: .requestHeaders)
            try container.encode(responseHeaders, forKey: .responseHeaders)
            try container.encode(code, forKey: .code)
            try container.encode(filename, forKey: .filename)
        case .template(method: let method,
                       urlPath: let urlPath,
                       code: let code,
                       filename: let filename,
                       templateInfo: let templateInfo):
            try container.encode(MockHTTPRouteType.template.rawValue, forKey: .type)
            try container.encode(method, forKey: .method)
            try container.encode(urlPath, forKey: .urlPath)
            try container.encode(code, forKey: .code)
            try container.encode(filename, forKey: .filename)
            try container.encode(TemplateParameter(with: templateInfo), forKey: .templateInfo)
        case .redirect(urlPath: let urlPath, destination: let destination):
            try container.encode(MockHTTPRouteType.redirect.rawValue, forKey: .type)
            try container.encode(urlPath, forKey: .urlPath)
            try container.encode(destination, forKey: .destination)
        case .collection(routes: let routes):
            try container.encode(MockHTTPRouteType.collection.rawValue, forKey: .type)
            try container.encode(routes, forKey: .routes)
        case .timeout(method: let method, urlPath: let urlPath, timeoutInSeconds: let timeoutInSeconds):
            try container.encode(MockHTTPRouteType.timeout.rawValue, forKey: .type)
            try container.encode(method, forKey: .method)
            try container.encode(urlPath, forKey: .urlPath)
            try container.encode(timeoutInSeconds, forKey: .timeoutInSeconds)
        }
    }
}

enum TemplateParameter: Hashable {
    case `nil`
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([TemplateParameter])
    case dictionary([String: TemplateParameter])
    
    var value: AnyHashable? {
        switch self {
        case .nil:
            return nil
        case .bool(let bool):
            return bool
        case .int(let int):
            return int
        case .double(let double):
            return double
        case .string(let string):
            return string
        case .array(let array):
            return array
        case .dictionary(let dictionary):
            return dictionary
        }
    }
    
    var string: String? {
        switch self {
        case .string(let value):
            return value
        default:
            return nil
        }
    }
    
    var int: Int? {
        switch self {
        case .int(let value):
            return value
        default:
            return nil
        }
    }
    
    var double: Double? {
        switch self {
        case .double(let value):
            return value
        default:
            return nil
        }
    }
    
    var bool: Bool? {
        switch self {
        case .bool(let value):
            return value
        default:
            return nil
        }
    }
    
    var array: [TemplateParameter]? {
        switch self {
        case .array(let value):
            return value
        default:
            return nil
        }
    }
    
    var dictionary: [String: TemplateParameter]? {
        switch self {
        case .dictionary(let value):
            return value
        default:
            return nil
        }
    }
    
    init(with value: AnyHashable) throws {
        if let string = value as? String {
            self = .string(string)
            return
        }
        if let bool = value as? Bool {
            self = .bool(bool)
            return
        }
        if let int = value as? Int {
            self = .int(int)
            return
        }
        if let double = value as? Double {
            self = .double(double)
            return
        }
        if let array = value as? [AnyHashable] {
            let list = try array.compactMap { try TemplateParameter(with: $0) }
            self = .array(list)
            return
        }
        if let dictionary = value as? [String: AnyHashable] {
            let dict = try dictionary.mapValues { try TemplateParameter(with: $0) }
            self = .dictionary(dict)
            return
        }
        if value as? NSNull != nil {
            self = .nil
            return
        }
        throw CustomCodableError.unableToEncode
    }
}

extension TemplateParameter: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard !container.decodeNil() else {
            self = .nil
            return
        }
        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }
        if let value = try? container.decode(Int.self) {
            self = .int(value)
            return
        }
        if let value = try? container.decode(Double.self) {
            self = .double(value)
            return
        }
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
            return
        }
        if let value = try? container.decode([String: TemplateParameter].self) {
            self = .dictionary(value)
            return
        }
        if let value = try? container.decode([TemplateParameter].self) {
            self = .array(value)
            return
        }
        throw CustomCodableError.unableToDecode
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .nil:
            try container.encodeNil()
        case .bool(let bool):
            try container.encode(bool)
        case .int(let int):
            try container.encode(int)
        case .double(let double):
            try container.encode(double)
        case .string(let string):
            try container.encode(string)
        case .array(let array):
            try container.encode(array)
        case .dictionary(let dictionary):
            try container.encode(dictionary)
        }
    }
}

private enum CustomCodableError: Error {
    case unableToDecode
    case unableToEncode
}

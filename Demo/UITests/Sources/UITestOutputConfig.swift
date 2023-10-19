//  UITestOutputConfig.swift

import Foundation
import CryptoKit

struct UITestOutputConfig {
    let className: String
    let functionName: String
    let basePath: String = "UITests"
    
    var functionNameMD5: String {
        let digest = Insecure.MD5.hash(data: functionName.data(using: .utf8) ?? Data())
        return digest.map {
            String(format: "%02hhx", $0)
        }.joined()
    }
    
    func appendRelativePath(url: URL) -> URL {
        var urlWithPath = url
        urlWithPath.appendPathComponent(basePath, isDirectory: true)
        urlWithPath.appendPathComponent(className, isDirectory: true)
        urlWithPath.appendPathComponent(functionNameMD5, isDirectory: true)
        return urlWithPath
    }
    
    func configFileName(url: URL?) -> URL {
        var urlWithPath = url ?? URL(fileURLWithPath: "")
        urlWithPath.appendPathExtension("json")
        return urlWithPath
    }
}

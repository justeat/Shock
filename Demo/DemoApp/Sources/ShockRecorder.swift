//  ShockRecorder.swift

import Foundation

class ShockRecorder {
    private var index = 1
    private let outputDirectory: URL
    private let outputConfig: UITestOutputConfig?
    internal let queue = DispatchQueue(label: "ShockRecorder", qos: .default)
    
    private let routeManager = MockRoutesManager()

    init(outputDirectory: URL, outputConfig: UITestOutputConfig?) {
        self.outputConfig = outputConfig
        if let outputConfig = outputConfig {
            self.outputDirectory = outputConfig.appendRelativePath(url: outputDirectory)
            print("[ShockRecorder] function: \(outputConfig.functionName) - \(outputConfig.functionNameMD5)")
            cleanDataFolder()
        } else {
            self.outputDirectory = outputDirectory
        }
    }
    
    private func cleanDataFolder() {
        do {
            try FileManager.default.removeItem(at: outputDirectory)
        } catch {
        }
    }
    
    func writeData(request: URLRequest, response: URLResponse, data: Data?) {
        guard let data = data,
              let url = request.url,
              let method = request.httpMethod else {
            return
        }
        queue.async { [weak self] in
            // TODO: Shock doesn't support different responses with the same url.path
            guard let self,
                  !self.routeManager.routeExists(response: response),
                  let index = self.writeDataToFile(data, url: url, method: method) else {
                return
            }
            self.routeManager.addMockHttpRoute(request: request, response: response, at: index)
            self.writeConfigToFile()
        }
    }
    
    @discardableResult
    private func writeDataToFile(_ data: Data, url: URL, method: String) -> Int? {
        do {
            try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true, attributes: nil)
            let name = routeManager.fileName(url: url, method: method, index: index)
            let outputFile = outputDirectory
                .appendingPathComponent(name)
                .appendingPathExtension("json")
            let output = String(data: data, encoding: .utf8)
            try output?.write(to: outputFile, atomically: true, encoding: .utf8)
            print("[ShockRecorder] filePath: \(outputFile)")
            index += 1
            return index - 1
        }
        catch {
            print("[ShockRecorder] error: \(error)")
        }
        return nil
    }
    
    func writeConfigToFile() {
        guard let outputConfig = outputConfig else {
            return
        }
        
        do {
            try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true, attributes: nil)
            let outputFile = outputConfig.configFileName(url: outputDirectory)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.withoutEscapingSlashes, .prettyPrinted]
            let collectionRoute = routeManager.collectionRoutes()
            let data = try encoder.encode(collectionRoute)
            try data.write(to: outputFile, options: [.atomic])
        } catch {
            print("[ShockRecorder] error: \(error)")
        }
    }
}

//  DogAPI.swift

import Foundation

struct DogAPI {
    
    let baseURL: URL
    let session: URLSession = .shared
    let shockRecorder: ShockRecorder?
    
    init(baseURL: URL, shockRecorder: ShockRecorder?) {
        self.baseURL = baseURL
        self.shockRecorder = shockRecorder
    }
    
    private func buildBreedsImage(value: String) -> URLRequest {
        let path = "/api/breeds/image/\(value)"
        let url = baseURL.appendingPathComponent(path)
        var request: URLRequest = URLRequest(url: url)
        request.allHTTPHeaderFields = ["Accept": "application/json"]
        request.httpMethod = "GET"
        return request
    }
    
    @available(iOS 15.0.0, *)
    func breedsImage(value: String) async throws -> String? {
        let request = buildBreedsImage(value: value)
        let (data, response) = try await session.data(for: request, delegate: nil)
        shockRecorder?.writeData(request: request, response: response, data: data)
        return String(data: data, encoding: .utf8)
    }
}

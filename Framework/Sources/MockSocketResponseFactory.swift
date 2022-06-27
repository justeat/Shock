//  MockSocketResponseFactory.swift

import Foundation

internal struct MockSocketResponseFactory {
   
    private func addLogStashSocketHandlerWithEchoClosure(_ echo: @escaping MockSocketRoute.LogStashEchoClosure,
                                                         to handlers: inout [MockNIOSocketHandler.SocketDataHandler]) {
        let parserClosure: MockNIOSocketHandler.SocketDataHandler = { (data, logging) in
            if let separator = "\n".data(using: String.Encoding.utf8)?.first {
                let messages = data.split(separator: separator)
                for message in messages {
                    if let json = try? JSONSerialization.jsonObject(with: message, options: []) {
                        echo("\(json)")
                    } else if let logging = logging {
                        logging("Couldn't parse message \(String(data: message, encoding: .utf8) ?? message.debugDescription)")
                    }
                }
            }
        }
        handlers.append(parserClosure)
    }
    
    private func addResponseFromRoute(route: MockSocketRoute,
                                      to handlers: inout [MockNIOSocketHandler.SocketDataHandler]) {
        switch route {
        case .logStashEcho(let closure):
            addLogStashSocketHandlerWithEchoClosure(closure, to: &handlers)
        case .collection(routes: let routes):
            routes.forEach { self.addResponseFromRoute(route: $0, to: &handlers) }
        }
    }
    
    func responseFromRoute(route: MockSocketRoute) -> MockNIOSocketHandler.SocketDataHandler {
        var handlers = [MockNIOSocketHandler.SocketDataHandler]()
        
        addResponseFromRoute(route: route, to: &handlers)
        return { (data, logger) in
            handlers.forEach { $0(data, logger) }
        }
    }
}

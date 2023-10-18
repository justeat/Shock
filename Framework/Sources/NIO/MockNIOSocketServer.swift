//  MockNIOSocketServer.swift

import Foundation
import NIO
import NIOHTTP1

class MockNIOSocketServer: MockNIOBaseServer {
    
    var socketDataHandler: MockNIOSocketHandler.SocketDataHandler?
    var loggingClosure: ((String?) -> Void)?
    
    func start(_ port: Int) throws {
        try start(port) { (channel) -> EventLoopFuture<Void> in
            // Ensure we don't read faster than we can write by adding the BackPressureHandler into the pipeline.
            channel.pipeline.addHandler(BackPressureHandler()).flatMap { _ in
                channel.pipeline.addHandler(MockNIOSocketHandler(dataHandler: self.socketDataHandler, loggingClosure: self.loggingClosure))
            }
        }
    }
}

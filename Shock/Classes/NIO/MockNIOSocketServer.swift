//
//  MockNIOSocketServer.swift
//  Shock
//
//  Created by Antonio Strijdom on 01/10/2020.
//

import Foundation
import NIO
import NIOHTTP1

enum MockNIOSocketServerError: Error {
    case missingSocketHandlerClosure
}

class MockNIOSocketServer: MockNIOBaseServer {
    
    public var socketDataHandler: MockNIOSocketHandler.SocketDataHandler?
    public var loggingClosure: ((String?) -> Void)?
    
    func start(_ port: Int) throws -> Void {
        guard let socketDataHandler = socketDataHandler else {
            throw MockNIOSocketServerError.missingSocketHandlerClosure
        }
        try start(port) { (channel) -> EventLoopFuture<Void> in
            // Ensure we don't read faster than we can write by adding the BackPressureHandler into the pipeline.
            channel.pipeline.addHandler(BackPressureHandler()).flatMap { v in
                channel.pipeline.addHandler(MockNIOSocketHandler(dataHandler: socketDataHandler, loggingClosure: self.loggingClosure))
            }
        }
    }
}

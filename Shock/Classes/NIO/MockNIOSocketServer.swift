//
//  MockNIOSocketServer.swift
//  Shock
//
//  Created by Antonio Strijdom on 01/10/2020.
//

import Foundation
import NIO
import NIOHTTP1

class MockNIOSocketServer: MockNIOBaseServer {
    
    public var socketDataHandler: MockNIOSocketHandler.SocketDataHandler?
    public var loggingClosure: ((String?) -> Void)?
    
    func start(_ port: Int) throws -> Void {
        try start(port) { (channel) -> EventLoopFuture<Void> in
            // Ensure we don't read faster than we can write by adding the BackPressureHandler into the pipeline.
            channel.pipeline.addHandler(BackPressureHandler()).flatMap { v in
                channel.pipeline.addHandler(MockNIOSocketHandler(dataHandler: self.socketDataHandler, loggingClosure: self.loggingClosure))
            }
        }
    }
}

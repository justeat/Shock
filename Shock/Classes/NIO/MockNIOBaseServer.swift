//
//  MockNIOServer.swift
//  Shock
//
//  Created by Antonio Strijdom on 01/10/2020.
//

import Foundation
import NIO

internal class MockNIOBaseServer {
    
    private let host = "localhost"
    // TODO: make this an option?
    private let allowHalfClosure = true
    
    private let group: MultiThreadedEventLoopGroup
    private let threadPool: NIOThreadPool
    
    private(set) var localAddress: String?
    
    init() {
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.threadPool = NIOThreadPool(numberOfThreads: 6)
    }
    
    func start(_ port: Int, childChannelInitializer: @escaping (Channel) -> EventLoopFuture<Void>) throws -> Void {
        threadPool.start()
        
        let socketBootstrap = ServerBootstrap(group: group)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

            // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer(childChannelInitializer)

            // Enable SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
            .childChannelOption(ChannelOptions.allowRemoteHalfClosure, value: allowHalfClosure)
        
        let channel = try { () -> Channel in
            try socketBootstrap.bind(host: host, port: port).wait()
        }()
        
        guard let channelLocalAddress = channel.localAddress else {
            fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
        }
        localAddress = "\(channelLocalAddress)"
    }
    
    func stop() {
        try! group.syncShutdownGracefully()
        try! threadPool.syncShutdownGracefully()
    }
}

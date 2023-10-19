//  MockNIOSocketHandler.swift

import Foundation
import NIO

class MockNIOSocketHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    typealias LoggingClosure = (String?) -> Void
    typealias SocketDataHandler = (Data, LoggingClosure?) -> Void
    
    private var received: Data?
    private var loggingClosure: LoggingClosure?
    private var dataHandler: SocketDataHandler?
    
    init(dataHandler: SocketDataHandler?,
         loggingClosure: LoggingClosure?) {
        self.dataHandler = dataHandler
        self.loggingClosure = loggingClosure
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        let readableBytes = buffer.readableBytes
        if readableBytes > 0, let received = buffer.readBytes(length: readableBytes) {
            let data = Data(bytes: received, count: readableBytes)
            if self.received == nil {
                self.received = Data()
            }
            self.received?.append(data)
        }
    }

    func channelReadComplete(context: ChannelHandlerContext) {
        if let data = self.received {
            dataHandler?(data, loggingClosure)
            if let separator = "\n".data(using: String.Encoding.utf8)?.first {
                let messages = data.split(separator: separator)
                print("Received \(messages.count) messages")
                for message in messages {
                    if let json = try? JSONSerialization.jsonObject(with: message, options: []) {
                        print("\(json)")
                    } else {
                        print("Couldn't parse message \(String(data: message, encoding: .utf8) ?? message.debugDescription)")
                    }
                }
            } else {
                fatalError("Couldn't encode newline??")
            }
        }
        self.received = nil
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        context.close(promise: nil)
    }
}

//
//  MockHTTPHandler.swift
//  Shock
//
//  Created by Antonio Strijdom on 08/05/2019.
//

import Foundation
import NIO
import NIOHTTP1

final class MockHTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    
    private let bundle: Bundle
    
    init(bundle: Bundle = Bundle.main) {
        self.bundle = bundle
    }
 
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let requestPart = self.unwrapInboundIn(data)
        
        switch requestPart {
        case .head(let request):
            print("Received request: \(request)")
            break
        case .body(_):
            break
        case .end(_):
            print("Request complete")
            break
        }
    }
}

//
//  SocketServerTests.swift
//  Shock_Tests
//
//  Created by Antonio Strijdom on 01/10/2020.
//  Copyright © 2020 Just Eat. All rights reserved.
//

import XCTest
import JustLog
import Shock

class SocketServerTests: ShockTestCase {
    
    func testFakeLogstash() {
        let expectation = self.expectation(description: "Expect log echo'd back")
        
        let route = MockSocketRoute.logStashEcho { (log) in
            expectation.fulfill()
        }
        server.setupSocket(route: route)
        server.start()
        
        let logger = Logger.shared
        logger.logstashHost = "localhost"
        logger.logstashPort = UInt16(server.selectedSocketPort)
        logger.enableLogstashLogging = true
        logger.logLogstashSocketActivity = true
        logger.logstashTimeout = 1.0
        logger.allowUntrustedServer = true
        logger.setup()
        
        logger.info("Hello world!")
        
        self.waitForExpectations(timeout: 6.0, handler: nil)
    }
}

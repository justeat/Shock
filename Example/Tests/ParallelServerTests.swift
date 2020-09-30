//
//  ParallelServerTests.swift
//  Shock_Tests
//
//  Created by Jack Newcombe on 30/09/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
import Shock

class ParallelServerTests: XCTestCase {

    func testParallelServerPortAssignment() throws {
        let range: ClosedRange<Int> = 9090...9099
        
        var servers: [MockServer] = []
        
        range.forEach { port in
            let server = MockServer(portRange: range, bundle: Bundle(for: ParallelServerTests.self))
            server.start()
            servers.append(server)
        }
        
        servers.enumerated().forEach { index, server in
            let port = UInt16(9090 + index)
            XCTAssertEqual(server.selectedPort, port)
            server.stop()
        }
        
    }

}

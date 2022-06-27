//  ParallelServerTests.swift

import XCTest
import Shock

class ParallelServerTests: XCTestCase {

    func testParallelServerPortAssignment() throws {
        let range: ClosedRange<Int> = 10000...10010
        
        var servers: [MockServer] = []
        
        range.forEach { port in
            let server = MockServer(portRange: range, bundle: Bundle.module)
            server.start()
            servers.append(server)
        }
        
        servers.enumerated().forEach { index, server in
            let port = range.lowerBound + index
            XCTAssertEqual(server.selectedHTTPPort, port)
            server.stop()
        }
    }
}

//  ShockTestCase.swift

import XCTest
import Shock

class ShockTestCase: XCTestCase {
    
    var server: MockServer!
    let timeout: TimeInterval = 2.0
    
    override func setUp() {
        super.setUp()
        server = MockServer(portRange: 9090...9099, bundle: Bundle.module)
        server.shouldSendNotFoundForMissingRoutes = true
        server.start()
    }
    
    override func tearDown() {
        server.stop()
        super.tearDown()
    }
}

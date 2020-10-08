//
//  ShockTestCase.swift
//  Shock_Tests
//
//  Created by Jack Newcombe on 07/10/2020.
//  Copyright © 2018 Just Eat. All rights reserved.
//

import XCTest
import Shock

class ShockTestCase: XCTestCase {
    
    var server: MockServer!
    let timeout: TimeInterval = 2.0
    
    override func setUp() {
        super.setUp()
        server = MockServer(portRange: 9090...9099, bundle: Bundle(for: CustomRouteTests.self))
        server.shouldSendNotFoundForMissingRoutes = true
        server.start()
    }
    
    override func tearDown() {
        server.stop()
        super.tearDown()
    }
    
}

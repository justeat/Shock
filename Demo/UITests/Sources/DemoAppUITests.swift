//  DemoAppUITests.swift

import XCTest
import Shock

enum DemoAppTestsError: Error {
    case resourceNotFound
}

final class DemoAppUITests: XCTestCase {
    
    private var mockServer: MockServer!
    private var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        continueAfterFailure = false
    }
    
    override func tearDown() {
        app.terminate()
        super.tearDown()
    }
    
    func setupMockHTTPRoute(route: MockHTTPRoute) {
        if mockServer != nil { mockServer.stop() }
        mockServer = MockServer(portRange: 9090...9099, bundle: Bundle(for: DemoAppUITests.self))
        mockServer.start()
        mockServer.setup(route: route)
    }
    
    func loadHTTPMockRoutes(outputConfig: UITestOutputConfig, mockAuthentication: Bool = true) throws -> MockHTTPRoute {
        do {
            let decoder = JSONDecoder()
            guard let url = Bundle(for: type(of: self)).url(forResource: outputConfig.functionNameMD5, withExtension: "json") else {
                throw DemoAppTestsError.resourceNotFound
            }
            let data = try Data(contentsOf: url)
            return try decoder.decode(MockHTTPRoute.self, from: data)
        } catch {
            return MockHTTPRoute.collection(routes: [])
        }
    }

    func testShockRecorder() throws {
        
        // Setup Shock
        let className = String(describing: Self.self)
        
        let outputConfig = UITestOutputConfig(
            className: className,
            functionName: #function
        )
        let route = try loadHTTPMockRoutes(outputConfig: outputConfig)
        setupMockHTTPRoute(route: route)
       
        // Setup App
        // Uncomment the following line if you want to call the API and record the response
//        app.launchArguments.append("SAVE_API_RESPONSES_ON_DISK")
        
        app.launchArguments.append("UI_TEST")
        app.launchEnvironment["UI_TEST_CLASS"] = className
        app.launchEnvironment["UI_TEST_FUNCTION"] = #function
        app.launchEnvironment["UI_TEST_SHOCK_PORT"] = "\(mockServer.selectedHTTPPort)"
        
        app.launch()
        
        // Run Tests
        app.staticTexts["Test Recorder"].tap()
        app.staticTexts["Perform Request"].tap()
        
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 3))
        let text = scrollView.staticTexts["RecorderViewController.label"]
        text.tap()
        XCTAssertTrue(text.label.contains("mastiff-english"))
    }
}

//  RecorderViewController.swift

import UIKit

public func shouldSaveApiResponsesOnDisk() -> Bool {
    ProcessInfo.processInfo.arguments.contains("SAVE_API_RESPONSES_ON_DISK")
}

public func isRunningUITests() -> Bool {
    ProcessInfo.processInfo.arguments.contains("UI_TEST")
}

public func testClassName() -> String? {
    ProcessInfo.processInfo.environment["UI_TEST_CLASS"]
}

public func testFunctionName() -> String? {
    ProcessInfo.processInfo.environment["UI_TEST_FUNCTION"]
}

public func testShockPort() -> String? {
    ProcessInfo.processInfo.environment["UI_TEST_SHOCK_PORT"]
}

public func testBaseURL() -> URL {
    if let port = testShockPort() {
        return URL(string: "http://localhost:\(port)")!
    } else {
        return URL(string: "http://localhost")!
    }
}

func buildBaseURL() -> URL {
    guard !isRunningUITests() || shouldSaveApiResponsesOnDisk()
        else {
        return testBaseURL()
    }
    return URL(string: "https://dog.ceo")!
}

func buildShockRecorderIfRequired() -> ShockRecorder? {
    guard
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
        shouldSaveApiResponsesOnDisk()
    else {
        return nil
    }
    let dataResponsesDirectory = documentsDirectory.appendingPathComponent("data_responses", isDirectory: true)
    if isRunningUITests(),
       let className = testClassName(),
       let functionName = testFunctionName() {
        return ShockRecorder(
            outputDirectory: dataResponsesDirectory,
            outputConfig: UITestOutputConfig(className: className, functionName: functionName)
        )
    }
    return ShockRecorder(outputDirectory: dataResponsesDirectory, outputConfig: nil)
}

class RecorderViewController: UIViewController {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var label: UILabel!
    @IBOutlet var button: UIButton!
    
    let shockRecorder = buildShockRecorderIfRequired()
    let baseURL: URL = buildBaseURL()
    lazy var apiClient = DogAPI(baseURL: baseURL, shockRecorder: shockRecorder)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        button.layer.cornerRadius = 8.0
        scrollView.layer.cornerRadius = 8.0
        label.accessibilityIdentifier = "RecorderViewController.label"
    }

    @IBAction func performRequest(sender: UIButton) {
        Task { @MainActor in
            do {
                let value = try await apiClient.breedsImage(value: "random")
                self.label.text = value
            } catch {
                self.label.text = error.localizedDescription
            }
            self.label.sizeToFit()
            self.scrollView.contentOffset = CGPoint(x: 0, y: 0)
        }
    }
}

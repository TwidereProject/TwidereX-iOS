//
//  TwidereXUITests.swift
//  TwidereXUITests
//
//  Created by Cirno MainasuK on 2020-8-31.
//

import XCTest

@MainActor
class TwidereXUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override class func tearDown() {
        super.tearDown()
        
        let app = XCUIApplication()
        print(app.debugDescription)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSmoke() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            // This measures how long it takes to launch your application.
            XCUIApplication().launch()
        }
    }
}

extension UInt64 {
    static let second: UInt64 = 1_000_000_000
}

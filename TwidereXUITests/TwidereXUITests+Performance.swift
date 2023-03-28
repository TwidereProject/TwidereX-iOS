//
//  TwidereXUITests+Performance.swift
//  TwidereXUITests
//
//  Created by MainasuK on 2023/3/28.
//  Copyright © 2023 Twidere. All rights reserved.
//

import XCTest

final class TwidereXUITests_Performance: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
}

extension TwidereXUITests_Performance {
    
    func testHomeTimelineScrollingAnimationPerformance() throws {
        let app = XCUIApplication()
        app.launch()

        let tableView = app.tables.firstMatch
        XCTAssert(tableView.waitForExistence(timeout: 5))

        let measureOptions = XCTMeasureOptions()
        measureOptions.invocationOptions = [.manuallyStop]

        measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric], options: measureOptions) {
            tableView.swipeUp(velocity: .fast)
            tableView.swipeUp(velocity: .fast)
            stopMeasuring()
            tableView.swipeDown(velocity: .fast)
            tableView.swipeDown(velocity: .fast)
        }
    }

}

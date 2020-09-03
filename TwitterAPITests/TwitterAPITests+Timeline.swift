//
//  TwitterAPITests+Timeline.swift
//  TwitterAPITests
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import XCTest
@testable import TwitterAPI

class TwitterAPITests_Timeline: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

extension TwitterAPITests_Timeline {
    
    func testHomeTimeline() throws {
        let jsonData = try TwitterAPITests.restoreJSON(filename: "home_timeline")
        let tweets = try Twitter.decoder.decode([Tweet].self, from: jsonData)
    }
}

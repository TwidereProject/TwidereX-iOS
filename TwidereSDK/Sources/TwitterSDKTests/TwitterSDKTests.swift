//
//  TwitterSDKTests.swift
//  TwitterSDKTests
//
//  Created by Cirno MainasuK on 2021-8-12.
//

import os.log
import XCTest
@testable import TwitterSDK

final class TwitterSDKTests: XCTestCase {
    
    let logger = Logger()
    
    func testSmoke() throws { }
}

// Note:
// only for unit test!
// https://gist.github.com/shobotch/5160017
extension TwitterSDKTests {
    
    var consumerKey: String { "3rJOl1ODzm9yZy63FACdg" }
    var consumerSecret: String { "5jPoQ5kQvMJFDYRNE8bQ4rHuds4xJqhvgNJM4awaE8" }
    
    func testOAuthRequestToken() async throws {
        let query = Twitter.API.OAuth.RequestTokenQuery(consumerKey: consumerKey, consumerSecret: consumerSecret)
        let response = try await Twitter.API.OAuth.requestToken(session: URLSession.shared, query: query)
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): response: \n\(response.debugDescription)")
        

    }
}

//
//  TwitterAPITests.swift
//  TwitterAPITests
//
//  Created by Cirno MainasuK on 2020-9-1.
//

import XCTest
@testable import TwitterAPI
@testable import StubMixer

class TwitterAPITests: XCTestCase {
    
    static var stubEncryptionKey: String? {
        return ProcessInfo.processInfo.environment["StubEncryptionKey"]
    }

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

extension TwitterAPITests {
    
    func testEncryptStubKey() {
        let key = TwitterAPITests.stubEncryptionKey
        XCTAssertNotNil(key)
    }
    
    func testMixStubJSON() throws {
        let url = Bundle(for: TwitterAPITests.self).url(forResource: "home_timeline", withExtension: "json", subdirectory: nil)
        XCTAssertNotNil(url)
        let key = TwitterAPITests.stubEncryptionKey!
        let nonce = url!.lastPathComponent
        let data = try Data(contentsOf: url!)
        
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            // mix JSON
            let message = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
            let combined = StubMixer.mix(message: message, use: key, nonce: nonce)
            try combined.write(to: url!, options: .atomic)
            print("mix:")
        } else {
            // restore JSON
            let message = StubMixer.restore(combined: data, use: key, nonce: nonce)
            try message.write(to: url!, options: .atomic)
            print("restore:")
        }
        
        // replace stub resource with mixed file or check original JSON
        print(url!)
    }
    
    static func restoreJSON(filename: String) throws -> Data {
        let url = Bundle(for: TwitterAPITests.self).url(forResource: filename, withExtension: "json", subdirectory: nil)
        XCTAssertNotNil(url)
        let nonce = url!.lastPathComponent
        let data = try Data(contentsOf: url!)

        if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            // bypass decryption
            let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
            return data
        } else {
            let key = TwitterAPITests.stubEncryptionKey!
            let message = StubMixer.restore(combined: data, use: key, nonce: nonce)
            return message
        }
    }
}

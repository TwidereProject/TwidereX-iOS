//
//  TwidereXTests.swift
//  TwidereXTests
//
//  Created by Cirno MainasuK on 2020-8-31.
//

import XCTest
@testable import TwidereX
import CryptoKit
import CryptoSwift

class TwidereXTests: XCTestCase {

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

extension TwidereXTests {
    
    @available(iOS 14.0, *)
    func testHKDF() throws {
        // CryptoKit
        let keyMaterial = SymmetricKey(size: .bits256)
        let salt: Data = {
            var sha256 = SHA256()
            sha256.update(data: Data(UUID().uuidString.utf8))
            let digest = sha256.finalize()
            return Data(digest)
        }()
        let symmetricKey = CryptoKit.HKDF<SHA256>.deriveKey(inputKeyMaterial: keyMaterial, salt: salt, info: Data("authentication key".utf8), outputByteCount: 32)
        
        // CryptoSwift
        let password = keyMaterial.withUnsafeBytes { Data($0) }
        let wrapKeyData = try CryptoSwift.HKDF(password: password.bytes, salt: salt.bytes, info: Data("authentication key".utf8).bytes, keyLength: 32, variant: .sha256).calculate()
        let symmetricKey2 = SymmetricKey(data: Data(wrapKeyData))
        
        XCTAssertEqual(symmetricKey, symmetricKey2)
    }
    
}

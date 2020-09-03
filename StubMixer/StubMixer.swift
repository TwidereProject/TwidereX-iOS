//
//  StubMixer.swift
//  StubMixer
//
//  Created by Cirno MainasuK on 2020-9-3.
//

import Foundation
import CryptoKit

public enum StubMixer {
    public static func mix(message: Data, use key: String, nonce: String) -> Data {
        var sha256 = SHA256()
        sha256.update(data: Data(key.utf8))
        sha256.update(data: Data(nonce.utf8))
        let keyDigest = sha256.finalize()
        let symmetricKey = SymmetricKey(data: keyDigest)
        
        let sealedBox = try! AES.GCM.seal(message, using: symmetricKey)
        return sealedBox.combined!
    }
    
    public static func restore(combined: Data, use key: String, nonce: String) -> Data {
        var sha256 = SHA256()
        sha256.update(data: Data(key.utf8))
        sha256.update(data: Data(nonce.utf8))
        let keyDigest = sha256.finalize()
        let symmetricKey = SymmetricKey(data: keyDigest)
        
        let sealedBox = try! AES.GCM.SealedBox(combined: combined)
        let message = try! AES.GCM.open(sealedBox, using: symmetricKey)
        return message
    }
}

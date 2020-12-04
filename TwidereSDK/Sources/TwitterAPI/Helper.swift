//
//  File.swift
//  
//
//  Created by Cirno MainasuK on 2020-10-16.
//

import Foundation

// MARK: - Helper

extension String {
    
    var urlEncoded: String {
        let customAllowedSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return self.addingPercentEncoding(withAllowedCharacters: customAllowedSet)!
    }
    
}

extension Dictionary {
    
    var queryString: String {
        var parts = [String]()
        
        for (key, value) in self {
            let query: String = "\(key)=\(value)"
            parts.append(query)
        }
        
        return parts.joined(separator: "&")
    }
    
    var urlEncodedQuery: String {
        var parts = [String]()
        
        for (key, value) in self {
            let keyString = "\(key)".urlEncoded
            let valueString = "\(value)".urlEncoded
            let query = "\(keyString)=\(valueString)"
            parts.append(query)
        }
        
        return parts.joined(separator: "&")
    }
    
}

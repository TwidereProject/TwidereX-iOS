//
//  TwitterReplySettings.swift
//  
//
//  Created by MainasuK on 2022-6-16.
//

import Foundation

final public class TwitterReplySettings: NSObject, Codable {
    
    public let value: String

    public init(
        value: String
    ) {
        self.value = value
    }
    
}

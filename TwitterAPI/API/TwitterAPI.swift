//
//  TwitterAPI.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-1.
//

import Foundation

public enum TwitterAPI {
    public static let endpoint = "https://api.twitter.com/"
    public static let timeoutInterval: TimeInterval = 10
    public static let jsonDecoder = JSONDecoder()
    
    public enum OAuth { }
}

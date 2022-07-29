//
//  History.swift
//  
//
//  Created by MainasuK on 2022-7-29.
//

import Foundation
import CoreDataStack

extension History {
    
    public var statusObject: StatusObject? {
        if let status = twitterStatus {
            return .twitter(object: status)
        }
        if let status = mastodonStatus {
            return .mastodon(object: status)
        }
        
        return nil
    }

}

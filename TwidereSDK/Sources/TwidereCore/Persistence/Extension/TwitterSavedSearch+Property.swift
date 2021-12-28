//
//  TwitterSavedSearch+Property.swift
//  
//
//  Created by MainasuK on 2021-12-24.
//

import Foundation
import CoreDataStack
import TwitterSDK

extension TwitterSavedSearch.Property {
    public init(entity: Twitter.Entity.SavedSearch) {
        self.init(
            id: entity.idStr,
            name: entity.name,
            query: entity.query,
            createdAt: entity.createdAt
        )
    }
}

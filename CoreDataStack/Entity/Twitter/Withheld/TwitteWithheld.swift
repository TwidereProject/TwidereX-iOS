//
//  TwitteWithheld.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-10-20.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData
import TwitterAPI

final public class TwitteWithheld: NSManagedObject {
    
    @NSManaged public private(set) var identifier: UUID
    @NSManaged public private(set) var createdAt: Date
    
    @NSManaged public private(set) var copyright: Bool
    @NSManaged public private(set) var countryCodes: [String]?
    @NSManaged public private(set) var scope: String?
    
    // one-to-one relationship
    @NSManaged public private(set) var tweet: Tweet?
    @NSManaged public private(set) var twitterUser: TwitterUser?
    
}

extension TwitteWithheld {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
        createdAt = Date()
    }
    
}

extension TwitteWithheld {
    
}

extension TwitteWithheld: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \TwitteWithheld.createdAt, ascending: false)]
    }
}

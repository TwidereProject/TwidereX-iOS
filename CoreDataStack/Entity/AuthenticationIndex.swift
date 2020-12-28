//
//  AuthenticationIndex.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-11-11.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData

final public class AuthenticationIndex: NSManagedObject {
    
    @NSManaged public private(set) var identifier: UUID
    
    @NSManaged public private(set) var platformRaw: String
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var activedAt: Date
    
    // one-to-one relationship
    @NSManaged public private(set) var twitterAuthentication: TwitterAuthentication?
    
}

extension AuthenticationIndex {
    public var platform: Platform? {
        return Platform(rawValue: platformRaw)
    }
}

extension AuthenticationIndex {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
        
        let now = Date()
        createdAt = now
        activedAt = now
    }
    
    @discardableResult
    public static func insert(into context: NSManagedObjectContext, property: Property) -> AuthenticationIndex {
        let authenticationIndex: AuthenticationIndex = context.insertObject()
        authenticationIndex.platformRaw = property.platform.rawValue
        return authenticationIndex
    }
    
    public func update(activedAt: Date) {
        if self.activedAt != activedAt {
            self.activedAt = activedAt
        }
    }
    
}

extension AuthenticationIndex {
    public enum Platform: String {
        case twitter
        case mastodon
    }
    
    public struct Property {
        public let platform: Platform
        
        public init(platform: AuthenticationIndex.Platform) {
            self.platform = platform
        }
    }
}

extension AuthenticationIndex: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \AuthenticationIndex.createdAt, ascending: false)]
    }
}

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
    @NSManaged public private(set) var activeAt: Date
    
    // one-to-one relationship
    @NSManaged public private(set) var twitterAuthentication: TwitterAuthentication?
    
}

extension AuthenticationIndex {
    public var platform: Platform {
        return Platform(rawValue: platformRaw) ?? .none
    }
}

extension AuthenticationIndex {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
        
        let now = Date()
        createdAt = now
        activeAt = now
    }
    
    @discardableResult
    public static func insert(into context: NSManagedObjectContext, property: Property) -> AuthenticationIndex {
        let authenticationIndex: AuthenticationIndex = context.insertObject()
        authenticationIndex.platformRaw = property.platform.rawValue
        return authenticationIndex
    }
    
    public func update(activeAt: Date) {
        if self.activeAt != activeAt {
            self.activeAt = activeAt
        }
    }
    
}

extension AuthenticationIndex {
    public enum Platform: String {
        case none
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
        return [NSSortDescriptor(keyPath: \AuthenticationIndex.activeAt, ascending: false)]
    }
}

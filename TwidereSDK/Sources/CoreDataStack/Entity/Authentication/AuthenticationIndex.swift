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
    public private(set) var platform: Platform {
        get {
            return Platform(rawValue: platformRaw) ?? .none
        }
        set {
            platformRaw = newValue.rawValue
        }
    }

    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var activeAt: Date
    
    // one-to-one relationship
    @NSManaged public private(set) var twitterAuthentication: TwitterAuthentication?
    @NSManaged public private(set) var mastodonAuthentication: MastodonAuthentication?
    
}

extension AuthenticationIndex {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()

        setPrimitiveValue(UUID(), forKey: #keyPath(AuthenticationIndex.identifier))
        
        let now = Date()
        setPrimitiveValue(now, forKey: #keyPath(AuthenticationIndex.createdAt))
        setPrimitiveValue(now, forKey: #keyPath(AuthenticationIndex.activeAt))
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> AuthenticationIndex {
        let authenticationIndex: AuthenticationIndex = context.insertObject()
        authenticationIndex.platform = property.platform
        return authenticationIndex
    }
    
    public func update(activeAt: Date) {
        if self.activeAt != activeAt {
            self.activeAt = activeAt
        }
    }
    
}

extension AuthenticationIndex {    
    public struct Property {
        public let platform: Platform
        
        public init(platform: Platform) {
            self.platform = platform
        }
    }
}

extension AuthenticationIndex: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \AuthenticationIndex.activeAt, ascending: false)]
    }
}

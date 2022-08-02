//
//  History.swift
//  
//
//  Created by MainasuK on 2022-7-29.
//

import Foundation
import CoreData

final public class History: NSManagedObject {
    
    public typealias Acct = Feed.Acct
    
    @NSManaged public private(set) var acctRaw: String
    // sourcery: autoGenerateProperty
    public var acct: Acct {
        get {
            Acct(rawValue: acctRaw) ?? .none
        }
        set {
            acctRaw = newValue.rawValue
        }
    }
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var timestamp: Date

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date
    
    // many-to-one relationship
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var twitterStatus: TwitterStatus?
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var twitterUser: TwitterUser?
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var mastodonStatus: MastodonStatus?
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var mastodonUser: MastodonUser?
    
}

extension History {
    @objc public var sectionIdentifierByDay: String? {
        get {
            let keyPath = #keyPath(History.sectionIdentifierByDay)
            willAccessValue(forKey: keyPath)
            let _identifier = primitiveValue(forKey: keyPath) as? String
            didAccessValue(forKey: keyPath)
            
            guard let identifier = _identifier else {
                let timestamp = self.timestamp
                let identifier = History.sectionIdentifier(from: timestamp)
                
                willChangeValue(forKey: keyPath)
                setPrimitiveValue(identifier, forKey: keyPath)
                didChangeValue(forKey: keyPath)
                
                return identifier
            }
            
            return identifier
        }
    }
}

extension History {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> History {
        let object: History = context.insertObject()
        object.configure(property: property)
        return object
    }
    
}

extension History: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \History.createdAt, ascending: false)]
    }
}

extension History {

    static func hasTwitterStatus() -> NSPredicate {
        return NSPredicate(format: "%K != nil", #keyPath(History.twitterStatus))
    }

    static func hasTwitterUser() -> NSPredicate {
        return NSPredicate(format: "%K != nil", #keyPath(History.twitterUser))
    }
    
    
    static func hasMastodonStatus() -> NSPredicate {
        return NSPredicate(format: "%K != nil", #keyPath(History.mastodonStatus))
    }
    
    static func hasMastodonUser() -> NSPredicate {
        return NSPredicate(format: "%K != nil", #keyPath(History.mastodonUser))
    }
    
    public static func predicate(acct: Acct) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(History.acctRaw), acct.rawValue)
    }
    
    public static func statusPredicate(acct: Acct) -> NSPredicate {
        switch acct {
        case .none:
            return History.predicate(acct: acct)
        case .twitter:
            return NSCompoundPredicate(andPredicateWithSubpredicates: [
                History.predicate(acct: acct),
                History.hasTwitterStatus()
            ])
        case .mastodon:
            return NSCompoundPredicate(andPredicateWithSubpredicates: [
                History.predicate(acct: acct),
                History.hasMastodonStatus()
            ])
        }
    }
    
    public static func userPredicate(acct: Acct) -> NSPredicate {
        switch acct {
        case .none:
            return History.predicate(acct: acct)
        case .twitter:
            return NSCompoundPredicate(andPredicateWithSubpredicates: [
                History.predicate(acct: acct),
                History.hasTwitterUser()
            ])
        case .mastodon:
            return NSCompoundPredicate(andPredicateWithSubpredicates: [
                History.predicate(acct: acct),
                History.hasMastodonUser()
            ])
        }
    }

}

// MARK: - AutoGenerateProperty
extension History: AutoGenerateProperty {
    // sourcery:inline:History.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let acct: Acct
        public let timestamp: Date
        public let createdAt: Date

    	public init(
    		acct: Acct,
    		timestamp: Date,
    		createdAt: Date
    	) {
    		self.acct = acct
    		self.timestamp = timestamp
    		self.createdAt = createdAt
    	}
    }

    public func configure(property: Property) {
    	self.acct = property.acct
    	self.timestamp = property.timestamp
    	self.createdAt = property.createdAt
    }

    public func update(property: Property) {
    	update(createdAt: property.createdAt)
    }

    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension History: AutoUpdatableObject {
    // sourcery:inline:History.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(createdAt: Date) {
    	if self.createdAt != createdAt {
    		self.createdAt = createdAt
    	}
    }
    public func update(twitterStatus: TwitterStatus?) {
    	if self.twitterStatus != twitterStatus {
    		self.twitterStatus = twitterStatus
    	}
    }
    public func update(twitterUser: TwitterUser?) {
    	if self.twitterUser != twitterUser {
    		self.twitterUser = twitterUser
    	}
    }
    public func update(mastodonStatus: MastodonStatus?) {
    	if self.mastodonStatus != mastodonStatus {
    		self.mastodonStatus = mastodonStatus
    	}
    }
    public func update(mastodonUser: MastodonUser?) {
    	if self.mastodonUser != mastodonUser {
    		self.mastodonUser = mastodonUser
    	}
    }
    // sourcery:end
    
    public func update(timestamp: Date) {
        if self.timestamp != timestamp {
            self.timestamp = timestamp
            
            setPrimitiveValue(nil, forKey: #keyPath(History.sectionIdentifierByDay))
        }
    }
}

extension History {
    
    public static func sectionIdentifier(from date: Date) -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        // yyyymmdd
        let identifier = String(year * 10000 + month * 100 + day)

        return identifier
    }
    
    public static func date(from sectionIdentifier: String) -> Date? {
        guard let integer = Int(sectionIdentifier) else { return nil }
        let year = integer / 10000
        let month = (integer - year * 10000) / 100
        let day = (integer - year * 10000 - month * 100)
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        
        guard let date = Calendar.current.date(from: dateComponents) else { return nil }
        return date
    }
    
}

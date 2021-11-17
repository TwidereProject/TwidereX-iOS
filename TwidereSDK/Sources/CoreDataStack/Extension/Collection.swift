//
//  Collection.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-10-14.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation
import CoreData

extension Collection where Iterator.Element: NSManagedObject {
    public func fetchFaults() {
        guard !self.isEmpty else { return }
        guard let context = self.first?.managedObjectContext else {
            fatalError("Managed object must have context")
        }
        let faults = self.filter { $0.isFault }
        guard let object = faults.first else { return }
        let request = NSFetchRequest<Iterator.Element>()
        request.entity = object.entity
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "self in %@", faults)
        do {
            let _ = try context.fetch(request)
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
}

//
//  AppContext.swift
//  Cebu
//
//  Created by Cirno MainasuK on 2020-8-10.
//  Copyright © 2020 Dimension. All rights reserved.
//

import Foundation
import Combine
import CoreData
import CoreDataStack

class AppContext: ObservableObject {
        
    let coreDataStack: CoreDataStack
    let managedObjectContext: NSManagedObjectContext
    let twitterAPIService: TwitterAPIService
    
    let documentStore: DocumentStore
    private var documentStoreSubscription: AnyCancellable!
        
    init() {
        documentStore = DocumentStore()
        
        let _coreDataStack = CoreDataStack()
        coreDataStack = _coreDataStack
        managedObjectContext = _coreDataStack.persistentContainer.viewContext
        twitterAPIService = TwitterAPIService()
        
        documentStoreSubscription = documentStore.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                self.objectWillChange.send()
            }
    }
    
}

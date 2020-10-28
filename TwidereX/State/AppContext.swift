//
//  AppContext.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-8-10.
//  Copyright © 2020 Dimension. All rights reserved.
//

import Foundation
import Combine
import CoreData
import CoreDataStack

class AppContext: ObservableObject {
    
    var disposeBag = Set<AnyCancellable>()
        
    let coreDataStack: CoreDataStack
    let managedObjectContext: NSManagedObjectContext
    
    let apiService: APIService
    let authenticationService: AuthenticationService
    
    let documentStore: DocumentStore
    private var documentStoreSubscription: AnyCancellable!
        
    init() {
        let _coreDataStack = CoreDataStack()
        let _managedObjectContext = _coreDataStack.persistentContainer.viewContext
        coreDataStack = _coreDataStack
        managedObjectContext = _managedObjectContext
        
        let _backgroundManagedObjectContext = _coreDataStack.persistentContainer.newBackgroundContext()
        let _apiService = APIService(
            managedObjectContext: _managedObjectContext,
            backgroundManagedObjectContext: _backgroundManagedObjectContext
        )
        apiService = _apiService
        
        authenticationService = AuthenticationService(managedObjectContext: _managedObjectContext, apiService: _apiService)
        
        documentStore = DocumentStore()
        documentStoreSubscription = documentStore.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                self.objectWillChange.send()
            }
    }
    
}

//
//  AppContext.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-8-10.
//  Copyright © 2020 Dimension. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack

class AppContext: ObservableObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    @Published var viewStateStore = ViewStateStore()
        
    let coreDataStack: CoreDataStack
    let managedObjectContext: NSManagedObjectContext
    let backgroundManagedObjectContext: NSManagedObjectContext
    
    let apiService: APIService
    let authenticationService: AuthenticationService
    
    let documentStore: DocumentStore
    private var documentStoreSubscription: AnyCancellable!
    
    let photoLibraryService = PhotoLibraryService()

    let overrideTraitCollection = CurrentValueSubject<UITraitCollection?, Never>(nil)

    init() {
        let _coreDataStack = CoreDataStack()
        let _managedObjectContext = _coreDataStack.persistentContainer.viewContext
        let _backgroundManagedObjectContext = _coreDataStack.persistentContainer.newBackgroundContext()
        coreDataStack = _coreDataStack
        managedObjectContext = _managedObjectContext
        backgroundManagedObjectContext = _backgroundManagedObjectContext
        
        let _apiService = APIService(backgroundManagedObjectContext: _backgroundManagedObjectContext)
        apiService = _apiService
        
        authenticationService = AuthenticationService(
            managedObjectContext: _managedObjectContext,
            backgroundManagedObjectContext: _backgroundManagedObjectContext,
            apiService: _apiService
        )
        
        documentStore = DocumentStore()
        documentStoreSubscription = documentStore.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                self.objectWillChange.send()
            }
        
        backgroundManagedObjectContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: backgroundManagedObjectContext)
            .sink { [weak self] notification in
                guard let self = self else { return }
                self.managedObjectContext.perform {
                    self.managedObjectContext.mergeChanges(fromContextDidSave: notification)
                }
            }
            .store(in: &disposeBag)

        Publishers.CombineLatest(
            UserDefaults.shared.publisher(for: \.useTheSystemFontSize).eraseToAnyPublisher(),
            UserDefaults.shared.publisher(for: \.customContentSizeCatagory)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] useTheSystemFontSize, customContentSizeCatagory in
            guard let self = self else { return }
            // let traitCollection = useTheSystemFontSize ? UITraitCollection(preferredContentSizeCategory: UIApplication.shared.preferredContentSizeCategory) : UITraitCollection(preferredContentSizeCategory: customContentSizeCatagory)
            let traitCollection = UITraitCollection(preferredContentSizeCategory: UIApplication.shared.preferredContentSizeCategory)
            self.overrideTraitCollection.value = traitCollection
        }
        .store(in: &disposeBag)
    }
    
}

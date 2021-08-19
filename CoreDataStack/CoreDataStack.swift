//
//  CoreDataStack.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2020-8-6.
//  Copyright © 2020 Dimension. All rights reserved.
//

import os.log
import Foundation
import Combine
import CoreData
import AppShared

public final class CoreDataStack {
    
    let logger = Logger(subsystem: "CoreDataStack", category: "persistence")
    
    private var disposeBag = Set<AnyCancellable>()
    
    private(set) var storeDescriptions: [NSPersistentStoreDescription]
    
    /// A persistent history token used for fetching transactions from the store.
    private var lastToken: NSPersistentHistoryToken?
    
    init(persistentStoreDescriptions storeDescriptions: [NSPersistentStoreDescription]) {
        self.storeDescriptions = storeDescriptions
        
        // Observe Core Data remote change notifications on the queue where the changes were made.
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .sink { notification in
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): Received a persistent store remote change notification")
                Task {
                    await self.fetchPersistentHistory()
                }
            }
            .store(in: &disposeBag)
    }
    
    public convenience init(databaseName: String = "shared_v2") {
        let storeURL = URL.storeURL(for: AppCommon.groupID, databaseName: databaseName)
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        // enable remote change notification
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        // enable persistent history tracking
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        self.init(persistentStoreDescriptions: [storeDescription])
    }
    
    public private(set) lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = CoreDataStack.persistentContainer()
        CoreDataStack.configure(persistentContainer: container, storeDescriptions: storeDescriptions)
        CoreDataStack.load(persistentContainer: container)

        return container
    }()

    static func persistentContainer() -> NSPersistentContainer {
        let bundles = [Bundle(for: TwitterAuthentication.self)]
        guard let managedObjectModel = NSManagedObjectModel.mergedModel(from: bundles) else {
            fatalError("cannot locate bundles")
        }
        
        let container = NSPersistentContainer(name: "CoreDataStack", managedObjectModel: managedObjectModel)
        return container
    }
    
    static func configure(persistentContainer container: NSPersistentContainer, storeDescriptions: [NSPersistentStoreDescription]) {
        container.persistentStoreDescriptions = storeDescriptions
    }
    
    static func load(persistentContainer container: NSPersistentContainer) {
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                if let reason = error.userInfo["reason"] as? String,
                   (reason == "Can't find mapping model for migration" || reason == "Persistent store migration failed, missing mapping model.")  {
                    if let storeDescription = container.persistentStoreDescriptions.first, let url = storeDescription.url {
                        try? container.persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
                        os_log("%{public}s[%{public}ld], %{public}s: cannot migrate model. rebuild database…", ((#file as NSString).lastPathComponent), #line, #function)
                    } else {
                        assertionFailure()
                    }
                }

                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
            // enable background context auto merge
            container.viewContext.automaticallyMergesChangesFromParent = true
            
            os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, storeDescription.debugDescription)
        })
    }
    
}

// WWDC20 - 10017
extension CoreDataStack {
    
    private func newTaskContext() -> NSManagedObjectContext {
        // Create a private queue context.
        /// - Tag: newBackgroundContext
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Set unused undoManager to nil for macOS (it is nil by default on iOS)
        // to reduce resource requirements.
        taskContext.undoManager = nil
        return taskContext
    }
    
    func fetchPersistentHistory() async {
        do {
            try await fetchPersistentHistoryTransactionsAndChanges()
        } catch {
            logger.debug("\(error.localizedDescription)")
        }
    }
    
    private func fetchPersistentHistoryTransactionsAndChanges() async throws {
        let taskContext = newTaskContext()
        taskContext.name = "persistentHistoryContext"
        logger.debug("Start fetching persistent history changes from the store...")
        
        try await taskContext.perform {
            // Execute the persistent history change since the last transaction.
            /// - Tag: fetchHistory
            let changeRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: self.lastToken)
            let historyResult = try taskContext.execute(changeRequest) as? NSPersistentHistoryResult
            if let history = historyResult?.result as? [NSPersistentHistoryTransaction],
               !history.isEmpty {
                self.mergePersistentHistoryChanges(from: history)
                return
            }
            
            self.logger.debug("No persistent history transactions found.")
            throw CoreDataStackError.persistentHistoryChangeError
        }
        
        logger.debug("Finished merging history changes.")
    }
    
    private func mergePersistentHistoryChanges(from history: [NSPersistentHistoryTransaction]) {
        self.logger.debug("Received \(history.count) persistent history transactions.")
        // Update view context with objectIDs from history change request.
        /// - Tag: mergeChanges
        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            for transaction in history {
                viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
                self.lastToken = transaction.token
            }
        }
    }
    
    enum CoreDataStackError: Error {
        case persistentHistoryChangeError
    }
    
}

extension CoreDataStack {
    
    public func rebuild() {
        let oldStoreURL = persistentContainer.persistentStoreCoordinator.url(for: persistentContainer.persistentStoreCoordinator.persistentStores.first!)
        try! persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: oldStoreURL, ofType: NSSQLiteStoreType, options: nil)
        
        CoreDataStack.load(persistentContainer: persistentContainer)
    }

}

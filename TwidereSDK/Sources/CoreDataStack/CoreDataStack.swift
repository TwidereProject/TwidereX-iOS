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
import TwidereCommon

public final class CoreDataStack {
    
    static let viewContextAuthorName = "CoreDataStack"
    
    let logger = Logger(subsystem: "CoreDataStack", category: "DB")
    
    private var disposeBag = Set<AnyCancellable>()
    
    private(set) var storeDescriptions: [NSPersistentStoreDescription]
        
    /// A persistent history token used for fetching transactions from the store.
    private var lastHistoryToken: NSPersistentHistoryToken?
    private lazy var lastHistoryTokenFileURL: URL = {
        let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("HistoryToken", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): create token file failure: \(error.localizedDescription)")
        }
        
        return url.appendingPathComponent("token.data", isDirectory: false)
    }()
    private func storeHistoryToken(_ token: NSPersistentHistoryToken) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
            try data.write(to: lastHistoryTokenFileURL)
            lastHistoryToken = token
        } catch {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): store token failure: \(error.localizedDescription)")
        }
    }
    private func loadHistoryToken() {
        do {
            let data = try Data(contentsOf: lastHistoryTokenFileURL)
            lastHistoryToken = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: data)
        } catch {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): load token failure: \(error.localizedDescription)")
        }
    }
    
    init(persistentStoreDescriptions storeDescriptions: [NSPersistentStoreDescription]) {
        self.storeDescriptions = storeDescriptions
    
        if let storeDescription = storeDescriptions.first {
            // enable remote change notification
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            // enable persistent history tracking
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        }
        
        // Observe Core Data remote change notifications on the queue where the changes were made.
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .sink { notification in
                Task {
                    do {
                        try await self.processRemoteStoreChange()
                    } catch {
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(error.localizedDescription)")
                    }
                }
            }
            .store(in: &disposeBag)
    }
    
    public convenience init(databaseName: String = "shared_v2") {
        let storeURL = URL.storeURL(for: AppCommon.groupID, databaseName: databaseName)
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
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
        configure(persistentContainer: container, storeDescriptions: storeDescriptions)
        load(persistentContainer: container)

        return container
    }()

    static func persistentContainer() -> NSPersistentContainer {
        let bundles = [Bundle.module]
        guard let managedObjectModel = NSManagedObjectModel.mergedModel(from: bundles) else {
            fatalError("cannot locate bundles")
        }
        
        let container = NSPersistentContainer(name: "CoreDataStack", managedObjectModel: managedObjectModel)
        return container
    }
    
    private func configure(persistentContainer container: NSPersistentContainer, storeDescriptions: [NSPersistentStoreDescription]) {
        container.persistentStoreDescriptions = storeDescriptions
    }
    
    private func load(persistentContainer container: NSPersistentContainer) {
        container.loadPersistentStores { storeDescription, error in
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
            
            // set merge policy
            container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            // set false and use persistent history tracking to merge changes
            container.viewContext.automaticallyMergesChangesFromParent = false
            
            os_log("%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, storeDescription.debugDescription)
        }
    }
    
}

// WWDC20 - 10017
// https://www.raywenderlich.com/14958063-modern-efficient-core-data
// https://www.avanderlee.com/swift/persistent-history-tracking-core-data/
// Note:
// call processRemoteStoreChange after container setup is required
// otherwise, the UI not update until context merge happen
extension CoreDataStack {

    // handle remote store change notification
    // seealso: `NSPersistentStoreRemoteChangeNotificationPostOptionKey`
    private func processRemoteStoreChange() async throws {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        let context = self.newTaskContext()
        context.transactionAuthor = "PersistentHistoryContext"
        context.name = "PersistentHistoryContext"

        try await context.perform {
            let changeRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: self.lastHistoryToken)

            let historyResult = try context.execute(changeRequest) as? NSPersistentHistoryResult
            guard let history = historyResult?.result as? [NSPersistentHistoryTransaction],
                  !history.isEmpty
            else { return }

            self.mergePersistentHistoryChanges(from: history)

            if let token = history.last?.token {
                self.storeHistoryToken(token)

                let deleteChangeRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: token)
                _ = try? context.execute(deleteChangeRequest)
            }
        }
    }

    public func newTaskContext() -> NSManagedObjectContext {
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        taskContext.undoManager = nil
        return taskContext
    }

    // Update view context with objectIDs from history change request.
    private func mergePersistentHistoryChanges(from history: [NSPersistentHistoryTransaction]) {
        self.logger.debug("Received \(history.count) persistent history transactions.")

        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            for transaction in history {
                viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
            }
        }
    }

}

extension CoreDataStack {
    
    public func rebuild() {
        let oldStoreURL = persistentContainer.persistentStoreCoordinator.url(for: persistentContainer.persistentStoreCoordinator.persistentStores.first!)
        try! persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: oldStoreURL, ofType: NSSQLiteStoreType, options: nil)
        
        load(persistentContainer: persistentContainer)
    }

}

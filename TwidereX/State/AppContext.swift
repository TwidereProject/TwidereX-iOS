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
import TwidereCommon
import TwidereCore

class AppContext: ObservableObject {
    
    var disposeBag = Set<AnyCancellable>()
    let logger = Logger(subsystem: "AppContext", category: "AppContext")
    
    @Published var viewStateStore = ViewStateStore()
        
    let coreDataStack: CoreDataStack
    let managedObjectContext: NSManagedObjectContext
    let backgroundManagedObjectContext: NSManagedObjectContext
    
    let apiService: APIService
    let authenticationService: AuthenticationService
    
    let mastodonEmojiService: MastodonEmojiService
    let publisherService: PublisherService
    
    let documentStore: DocumentStore
    private var documentStoreSubscription: AnyCancellable!
    
    let photoLibraryService = PhotoLibraryService()
    // let videoPlaybackService = VideoPlaybackService()
    
    let timestampUpdatePublisher = Timer.publish(every: 1.0, on: .main, in: .common)
        .autoconnect()
        .share()
        .eraseToAnyPublisher()

    init(appSecret: AppSecret) {
        let _coreDataStack = CoreDataStack()
        let _managedObjectContext = _coreDataStack.persistentContainer.viewContext
        let _backgroundManagedObjectContext = _coreDataStack.newTaskContext()
        coreDataStack = _coreDataStack
        managedObjectContext = _managedObjectContext
        backgroundManagedObjectContext = _backgroundManagedObjectContext
        
        let _apiService = APIService(backgroundManagedObjectContext: _backgroundManagedObjectContext)
        apiService = _apiService
        
        authenticationService = AuthenticationService(
            managedObjectContext: _managedObjectContext,
            backgroundManagedObjectContext: _backgroundManagedObjectContext,
            apiService: _apiService,
            appSecret: appSecret
        )
        
        mastodonEmojiService = MastodonEmojiService()
        publisherService = PublisherService(
            apiService: _apiService,
            appSecret: appSecret
        )
        
        documentStore = DocumentStore()
        documentStoreSubscription = documentStore.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                self.objectWillChange.send()
            }
    }
    
}

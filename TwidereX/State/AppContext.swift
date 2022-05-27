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
import StoreKit

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
    let playerService = PlayerService()
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
        
        setupStoreReview()
    }
    
    private func setupStoreReview() {
        guard UserDefaults.shared.lastVersionPromptedForReview == nil else { return }
        
        // tigger store review when hit 50 times interact
        let limit = 50
        
        UserDefaults.shared.publisher(for: \.storeReviewInteractTriggerCount)
            .removeDuplicates()
            .throttle(for: 2, scheduler: DispatchQueue.main, latest: false)
            .sink { count in
                guard count > limit else { return }
                guard UserDefaults.shared.lastVersionPromptedForReview == nil else { return }
                
                let _windowScene: UIWindowScene? = {
                    let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
                    if let keyWindowScene = windowScenes.first(where: { $0.keyWindow != nil }) {
                        return keyWindowScene
                    } else {
                        return windowScenes.first
                    }
                }()
                guard let windowScene = _windowScene else {
                    assertionFailure()
                    return
                }
                
                let version = UIApplication.appVersion()
                UserDefaults.shared.lastVersionPromptedForReview = version
                SKStoreReviewController.requestReview(in: windowScene)
            }
            .store(in: &disposeBag)
        
    }
    
}

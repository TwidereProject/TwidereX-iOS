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
import StoreKit

public class AppContext: ObservableObject {
    
    var disposeBag = Set<AnyCancellable>()
    let logger = Logger(subsystem: "AppContext", category: "AppContext")
        
    public let coreDataStack: CoreDataStack
    public let managedObjectContext: NSManagedObjectContext
    public let backgroundManagedObjectContext: NSManagedObjectContext
    
    public let apiService: APIService
    public let authenticationService: AuthenticationService
    
    public let mastodonEmojiService: MastodonEmojiService
    public let publisherService: PublisherService
    
    public let photoLibraryService = PhotoLibraryService()
    public let playerService = PlayerService()
    
    public let timestampUpdatePublisher = Timer.publish(every: 1.0, on: .main, in: .common)
        .autoconnect()
        .share()
        .eraseToAnyPublisher()

    public init(appSecret: AppSecret) {
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

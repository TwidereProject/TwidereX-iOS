//
//  APIService.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-1.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack
import TwitterSDK
import AlamofireImage
// import AlamofireNetworkActivityIndicator

public final class APIService {
        
    var disposeBag = Set<AnyCancellable>()
    
    // internal
    let session: URLSession
    var homeTimelineRequestThrottler = RequestThrottler()
    let logger = Logger(subsystem: "APIService", category: "API")
    
    // input
    public let backgroundManagedObjectContext: NSManagedObjectContext

    // output
    public let error = PassthroughSubject<AppError, Never>()
    
    public init(backgroundManagedObjectContext: NSManagedObjectContext) {
        self.backgroundManagedObjectContext = backgroundManagedObjectContext
        self.session = URLSession(configuration: .default)
        
        // setup cache. 10MB RAM + 50MB Disk
        URLCache.shared = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024, diskPath: nil)
        
        // enable network activity manager for AlamofireImage
        // NetworkActivityIndicatorManager.shared.isEnabled = true
        // NetworkActivityIndicatorManager.shared.startDelay = 0.2
        // NetworkActivityIndicatorManager.shared.completionDelay = 0.5
    }
    
}

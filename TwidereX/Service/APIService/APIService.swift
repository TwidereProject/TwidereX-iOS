//
//  APIService.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-1.
//

import os.log
import func QuartzCore.CACurrentMediaTime
import Foundation
import Combine
import CoreData
import TwitterAPI
import AlamofireImage

final class APIService {
        
    var disposeBag = Set<AnyCancellable>()
    
    let session: URLSession
    
    // internal
    var homeTimelineRequestThrottler = RequestThrottler()
    
    // input
    let managedObjectContext: NSManagedObjectContext
    let backgroundManagedObjectContext: NSManagedObjectContext
    
    // output
    let error = CurrentValueSubject<Error?, Never>(nil)
    
    init(managedObjectContext: NSManagedObjectContext, backgroundManagedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.backgroundManagedObjectContext = backgroundManagedObjectContext
        self.session = URLSession(configuration: .default)
        
        // setup cache. 10MB RAM + 50MB Disk
        URLCache.shared = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024, diskPath: nil)
        
        backgroundManagedObjectContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: backgroundManagedObjectContext)
            .sink { notification in
                managedObjectContext.perform {
                    managedObjectContext.mergeChanges(fromContextDidSave: notification)
                }
            }
            .store(in: &disposeBag)
    }
    
}

extension APIService {
    public enum Persist { }
    public enum CoreData {
        public enum V2 { }
    }
}

extension APIService {
    enum APIError: Error {
        case silent(SilentError)        
        case accountTemporarilyLocked
    }
    
    enum SilentError {
        case requestThrottle
        case badRequest
    }
}

extension APIService {
    
    /// https://developer.twitter.com/en/docs/twitter-api/v1/rate-limits
    final class RequestThrottler {
        var rateLimit: RateLimit?
        
        struct RateLimit {
            let limit: Int
            let remaining: Int
            let resetAt: CFTimeInterval     // independent system clock
        }
        
        static func weights(limit: Int) -> [Int] {
            // divide limit into 5 group
            let groupSize = limit / 5
            let groupedReminds = limit % 5
            
            var weights: [[Int]] = []
            for weight in 1...5 {
                if weight != 5 {
                    weights.append(Array(repeating: weight, count: groupSize))
                } else {
                    let element = Array(repeating: weight, count: groupSize + groupedReminds + 1)      // 1 more for reset anchor
                    weights.append(element)
                }
            }
            return weights.flatMap { $0 }
        }
        
        func available(windowSizeInSec window: TimeInterval) -> Bool {
            guard let rateLimit = rateLimit else { return true }
            
            let current = CACurrentMediaTime()
            if current > rateLimit.resetAt {
                return true
            }
            
            let weights = RequestThrottler.weights(limit: rateLimit.limit)
            let secPerWeight = window / TimeInterval(weights.reduce(0, +))
            let remainingWeight = TimeInterval(weights.suffix(rateLimit.remaining).reduce(0, +))
            let requestStop = rateLimit.resetAt - (secPerWeight * remainingWeight)
            
            let available = current > requestStop
            if !available {
                let waitInterval = requestStop - current
                os_log("%{public}s[%{public}ld], %{public}s: request throttle. Please wait %.2fs", ((#file as NSString).lastPathComponent), #line, #function, waitInterval)
            }
            
            return available
        }
        
    }
}

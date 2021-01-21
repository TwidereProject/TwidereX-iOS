//
//  APIService+Account.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-28.
//

import Foundation
import Combine
import CoreDataStack
import CommonOSLog
import TwitterAPI

extension APIService {
    
    public func verifyCredentials(authorization: Twitter.API.OAuth.Authorization) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        return Twitter.API.Account.verifyCredentials(session: session, authorization: authorization)
            .flatMap { response -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> in
                let log = OSLog.api
                let entity = response.value
                
                return self.backgroundManagedObjectContext.performChanges {
                    let (twitterUser, isCreated) = APIService.CoreData.createOrMergeTwitterUser(into: self.backgroundManagedObjectContext, for: nil, entity: entity, networkDate: response.networkDate, log: log)
                    let flag = isCreated ? "+" : "-"
                    os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: twetter user [%s](%s)%s verifed", ((#file as NSString).lastPathComponent), #line, #function, flag, twitterUser.id, twitterUser.username)
                }
                .setFailureType(to: Error.self)
                .map { _ in return response }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
}

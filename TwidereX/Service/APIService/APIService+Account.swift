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
            .handleEvents(receiveOutput: { [weak self] response in
                guard let self = self else { return }
                
                let log = OSLog.api
                let entity = response.value
                let (twitterUser, isCreated) = APIService.CoreData.createOrMergeTwitterUser(into: self.backgroundManagedObjectContext, for: nil, entity: entity, networkDate: response.networkDate, log: log)
                let flag = isCreated ? "+" : "-"
                os_log(.info, log: log, "%{public}s[%{public}ld], %{public}s: twetter user [%s](%s)%s verifed", ((#file as NSString).lastPathComponent), #line, #function, flag, twitterUser.id, twitterUser.username)
            })
            .eraseToAnyPublisher()
    }
    
}

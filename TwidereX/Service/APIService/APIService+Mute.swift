//
//  APIService+Mute.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-13.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import TwitterSDK
import CoreData
import CoreDataStack
import CommonOSLog

extension APIService {

    func toggleMute(
        for twitterUser: TwitterUser,
        activeTwitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        
        return muteUpdateLocal(
            twitterUserObjectID: twitterUser.objectID,
            twitterAuthenticationBox: activeTwitterAuthenticationBox
        )
        .receive(on: DispatchQueue.main)
        .handleEvents { _ in
            impactFeedbackGenerator.prepare()
        } receiveOutput: { _ in
            impactFeedbackGenerator.impactOccurred()
        } receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                // TODO: handle error
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: local mute state update fail", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                assertionFailure(error.localizedDescription)
            case .finished:
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: local mute state update success", ((#file as NSString).lastPathComponent), #line, #function)
            }
        }
        .map { muteUpdateQueryKind, targetTwitterUserID in
            self.muteUpdateRemote(
                muteUpdateQueryKind: muteUpdateQueryKind,
                twitterUserID: targetTwitterUserID,
                twitterAuthenticationBox: activeTwitterAuthenticationBox
            )
        }
        .switchToLatest()
        .receive(on: DispatchQueue.main)
        .handleEvents(receiveCompletion: { [weak self] completion in
            guard let self = self else { return }
            switch completion {
            case .failure(let error):
                os_log("%{public}s[%{public}ld], %{public}s: [Mute] remote mute update fail: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                
                if let responseError = error as? Twitter.API.Error.ResponseError,
                   let twitterAPIError = responseError.twitterAPIError {
                    switch twitterAPIError {
                    case .accountIsTemporarilyLocked, .rateLimitExceeded, .blockedFromRequestFollowingThisUser:
                        self.error.send(.explicit(.twitterResponseError(responseError)))
                    default:
                        break
                    }
                }
                
                // rollback
                self.muteUpdateLocal(
                    twitterUserObjectID: twitterUser.objectID,
                    twitterAuthenticationBox: activeTwitterAuthenticationBox
                )
                .sink { completion in
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Mute] rollback finish", ((#file as NSString).lastPathComponent), #line, #function)
                } receiveValue: { _ in
                    // do nothing
                    notificationFeedbackGenerator.prepare()
                    notificationFeedbackGenerator.notificationOccurred(.error)
                }
                .store(in: &self.disposeBag)
                
                
            case .finished:
                notificationFeedbackGenerator.notificationOccurred(.success)
                os_log("%{public}s[%{public}ld], %{public}s: [Mute] remote mute update success", ((#file as NSString).lastPathComponent), #line, #function)
            }
        })
        .eraseToAnyPublisher()
    }
    
}

extension APIService {
    
    // update database local and return query update type for remote request
    func muteUpdateLocal(
        twitterUserObjectID: NSManagedObjectID,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<(Twitter.API.Mute.MuteUpdateQuery.QueryKind, TwitterUser.ID), Error> {
        let requestTwitterUserID = twitterAuthenticationBox.twitterUserID
        
        var _targetTwitterUserID: TwitterUser.ID?
        var _queryType: Twitter.API.Mute.MuteUpdateQuery.QueryKind?
        let managedObjectContext = backgroundManagedObjectContext
        
        return managedObjectContext.performChanges {
            let _requestTwitterUser: TwitterUser? = {
                let request = TwitterUser.sortedFetchRequest
                request.predicate = TwitterUser.predicate(idStr: requestTwitterUserID)
                request.fetchLimit = 1
                request.returnsObjectsAsFaults = false
                do {
                    return try managedObjectContext.fetch(request).first
                } catch {
                    assertionFailure(error.localizedDescription)
                    return nil
                }
            }()
            
            guard let requestTwitterUser = _requestTwitterUser else {
                assertionFailure()
                return
            }
            
            let twitterUser = managedObjectContext.object(with: twitterUserObjectID) as! TwitterUser
            _targetTwitterUserID = twitterUser.id
            
            let isMuting = (twitterUser.mutingBy ?? Set()).contains(where: { $0.id == requestTwitterUserID })
            if isMuting {
                _queryType = .destroy
            } else {
                _queryType = .create
            }
//            twitterUser.update(muting: !isMuting, by: requestTwitterUser)
        }
        .tryMap { result in
            switch result {
            case .success:
                guard let targetTwitterUserID = _targetTwitterUserID,
                      let queryType = _queryType else {
                    throw APIError.implicit(.badRequest)
                }
                return (queryType, targetTwitterUserID)
                
            case .failure(let error):
                assertionFailure(error.localizedDescription)
                throw error
            }
        }
        .eraseToAnyPublisher()
    }
    
    func muteUpdateRemote(
        muteUpdateQueryKind: Twitter.API.Mute.MuteUpdateQuery.QueryKind,
        twitterUserID: TwitterUser.ID,
        twitterAuthenticationBox: AuthenticationService.TwitterAuthenticationBox
    ) -> AnyPublisher<Twitter.Response.Content<Twitter.Entity.User>, Error> {
        let authorization = twitterAuthenticationBox.twitterAuthorization
        let query = Twitter.API.Mute.MuteUpdateQuery(
            userID: twitterUserID,
            queryKind: muteUpdateQueryKind
        )
        return Twitter.API.Mute.mute(
            session: session,
            authorization: authorization,
            query: query
        )
        .handleEvents(receiveCompletion: { [weak self] completion in
            guard let self = self else { return }
            switch completion {
            case .failure(let error):
                if let responseError = error as? Twitter.API.Error.ResponseError {
                    switch responseError.twitterAPIError {
                    case .accountIsTemporarilyLocked, .rateLimitExceeded, .blockedFromRequestFollowingThisUser:
                        self.error.send(.explicit(.twitterResponseError(responseError)))
                    default:
                        break
                    }
                }
            case .finished:
                break
            }
        })
        .eraseToAnyPublisher()
    }
    
}

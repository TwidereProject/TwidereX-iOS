//
//  TwitterStatusPublisher.swift
//  
//
//  Created by MainasuK on 2021-11-26.
//

import Foundation
import TwidereCommon
import TwitterSDK
import TwidereCore
import CoreDataStack

public final class TwitterStatusPublisher: NSObject, ProgressReporting {
    
    // Input
    
    // author
    public let author: TwitterUser
    // refer
    public let replyTo: ManagedObjectRecord<TwitterStatus>?
    public let excludeReplyUserIDs: [Twitter.Entity.V2.User.ID]
    // status content
    public let content: String
    // media
    public let attachmentViewModels: [AttachmentViewModel]
    // location
    public let place: Twitter.Entity.Place?
    
    // Output
    let _progress = Progress()
    public var progress: Progress { _progress }
    @Published var _state: StatusPublisherState = .pending
    public var state: Published<StatusPublisherState>.Publisher { $_state }
    
    public init(
        apiService: APIService,
        author: TwitterUser,
        replyTo: ManagedObjectRecord<TwitterStatus>?,
        excludeReplyUserIDs: [Twitter.Entity.V2.User.ID],
        content: String,
        attachmentViewModels: [AttachmentViewModel],
        place: Twitter.Entity.Place?
    ) {
        self.author = author
        self.replyTo = replyTo
        self.excludeReplyUserIDs = excludeReplyUserIDs
        self.content = content
        self.attachmentViewModels = attachmentViewModels
        self.place = place
        // end init
    }
    
}

extension TwitterStatusPublisher: StatusPublisher {
    public func publish(
        api: APIService,
        appSecret: AppSecret
    ) async throws -> StatusPublishResult {
        let publishAttachmentTaskWeight: Int64 = 100
        let publishAttachmentTaskCount: Int64 = Int64(attachmentViewModels.count) * publishAttachmentTaskWeight
        
        let publishStatusTaskWeight: Int64 = 20
        let publishStatusTaskCount: Int64 = publishStatusTaskWeight
        
        let taskCount = [
            publishAttachmentTaskCount,
            publishStatusTaskCount
        ].reduce(0, +)
        progress.totalUnitCount = taskCount
        progress.completedUnitCount = 0
        
        let _authenticationContext: TwitterAuthenticationContext? = await api.backgroundManagedObjectContext.perform {
            guard let authentication = self.author.twitterAuthentication else { return nil }
            return TwitterAuthenticationContext(authentication: authentication, appSecret: appSecret)
        }
        guard let authenticationContext = _authenticationContext else {
            throw AppError.implicit(.authenticationMissing)
        }
        
        let uploadContext = AttachmentViewModel.UploadContext(
            apiService: api,
            authenticationContext: .twitter(authenticationContext: authenticationContext)
        )
        
        var mediaIDs: [String] = []
        for attachmentViewModel in attachmentViewModels {
            // set progress
            progress.addChild(attachmentViewModel.progress, withPendingUnitCount: publishAttachmentTaskWeight)
            // upload media
            do {
                let result = try await attachmentViewModel.upload(context: uploadContext)
                guard case let .twitter(response) = result else {
                    assertionFailure()
                    continue
                }
                let mediaID = response.value.mediaIDString
                mediaIDs.append(mediaID)
            } catch {
                _state = .failure(error)
                throw error
            }
        }
        
        let publishResponse = try await api.publishTwitterStatus(
            content: content,
            mediaIDs: mediaIDs.isEmpty ? nil : mediaIDs,
            placeID: place?.id,
            replyTo: replyTo,
            excludeReplyUserIDs: excludeReplyUserIDs.isEmpty ? nil : excludeReplyUserIDs,
            twitterAuthenticationContext: authenticationContext
        )
        progress.completedUnitCount += publishStatusTaskCount
        _state = .success
        
        return .twitter(publishResponse)
    }
}

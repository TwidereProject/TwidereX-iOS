//
//  TwitterStatusPublisher.swift
//  
//
//  Created by MainasuK on 2021-11-26.
//

import os.log
import Foundation
import TwidereCore
import TwitterSDK
import CoreDataStack

public final class TwitterStatusPublisher: NSObject, ProgressReporting {
    
    let logger = Logger(subsystem: "TwitterStatusPublisher", category: "Publisher")
    
    // input
    
    // author
    public let author: TwitterUser
    // refer reply-to
    public let replyTo: ManagedObjectRecord<TwitterStatus>?
    public let excludeReplyUserIDs: [Twitter.Entity.V2.User.ID]
    // refer quote
    public let quote: ManagedObjectRecord<TwitterStatus>?
    // status content
    public let content: String
    // location
    public let place: Twitter.Entity.Place?
    // poll
    public let poll: Twitter.API.V2.Status.Poll?
    // reply settings
    public let replySettings: Twitter.Entity.V2.Tweet.ReplySettings
    // media
    public let attachmentViewModels: [AttachmentViewModel]
    
    // output
    let _progress = Progress()
    public var progress: Progress { _progress }
    @Published var _state: StatusPublisherState = .pending
    public var state: Published<StatusPublisherState>.Publisher { $_state }
    
    public init(
        apiService: APIService,
        author: TwitterUser,
        replyTo: ManagedObjectRecord<TwitterStatus>?,
        excludeReplyUserIDs: [Twitter.Entity.V2.User.ID],
        quote: ManagedObjectRecord<TwitterStatus>?,
        content: String,
        place: Twitter.Entity.Place?,
        poll: Twitter.API.V2.Status.Poll?,
        replySettings: Twitter.Entity.V2.Tweet.ReplySettings,
        attachmentViewModels: [AttachmentViewModel]
    ) {
        self.author = author
        self.replyTo = replyTo
        self.excludeReplyUserIDs = excludeReplyUserIDs
        self.quote = quote
        self.content = content
        self.place = place
        self.poll = poll
        self.replySettings = replySettings
        self.attachmentViewModels = attachmentViewModels
        // end init
    }
    
}

// MARK: - StatusPublisher
extension TwitterStatusPublisher: StatusPublisher {
    public func publish(
        api: APIService,
        secret: AppSecret.Secret
    ) async throws -> StatusPublishResult {
        let publishAttachmentTaskWeight: Int64 = 100
        let publishAttachmentTaskCount: Int64 = Int64(attachmentViewModels.count) * publishAttachmentTaskWeight

        let publishStatusTaskCount: Int64 = 20

        let taskCount = [
            publishAttachmentTaskCount,
            publishStatusTaskCount
        ].reduce(0, +)
        progress.totalUnitCount = taskCount
        progress.completedUnitCount = 0
        
        let managedObjectContext = api.backgroundManagedObjectContext

        let _authenticationContext: TwitterAuthenticationContext? = await author.managedObjectContext?.perform {
            guard let authentication = self.author.twitterAuthentication else { return nil }
            return TwitterAuthenticationContext(authentication: authentication, secret: secret)
        }
        guard let authenticationContext = _authenticationContext else {
            throw AppError.implicit(.authenticationMissing)
        }

        // Task: media
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

        // Task: status
        let publishResponse = try await api.publishTwitterStatus(
            query: Twitter.API.V2.Status.PublishQuery(
                forSuperFollowersOnly: nil,
                geo: {
                    guard let place = self.place else { return nil }
                    return .init(placeID: place.id)
                }(),
                media: {
                    guard !mediaIDs.isEmpty else { return nil }
                    return .init(mediaIDs: mediaIDs)
                }(),
                poll: poll,
                reply: await {
                    guard let replyTo = self.replyTo else { return nil }
                    let _replyToID: Twitter.Entity.V2.Tweet.ID? = await managedObjectContext.perform {
                        guard let replyTo = replyTo.object(in: managedObjectContext) else { return nil }
                        return replyTo.id
                    }
                    guard let replyToID = _replyToID else { return nil }
                    return .init(
                        excludeReplyUserIDs: self.excludeReplyUserIDs,
                        inReplyToTweetID: replyToID
                    )
                }(),
                quoteTweetID: {
                    guard let quote = self.quote else { return nil }
                    let _quoteID: Twitter.Entity.V2.Tweet.ID? = await managedObjectContext.perform {
                        guard let quote = quote.object(in: managedObjectContext) else { return nil }
                        return quote.id
                    }
                    guard let quoteID = _quoteID else { return nil }
                    return quoteID
                }(),
                replySettings: replySettings,
                text: content
            ),
            twitterAuthenticationContext: authenticationContext
        )
        
//        let publishResponse = try await api.publishTwitterStatus(
//            content: content,
//            mediaIDs: mediaIDs.isEmpty ? nil : mediaIDs,
//            placeID: place?.id,
//            replyTo: replyTo,
//            excludeReplyUserIDs: excludeReplyUserIDs.isEmpty ? nil : excludeReplyUserIDs,
//            twitterAuthenticationContext: authenticationContext
//        )
        
        progress.completedUnitCount += publishStatusTaskCount
        _state = .success
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): status published: \(publishResponse.value.data.id)")

        return .twitter(publishResponse)
    }
}

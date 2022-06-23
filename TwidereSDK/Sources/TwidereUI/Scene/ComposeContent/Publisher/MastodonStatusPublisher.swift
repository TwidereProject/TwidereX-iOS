//
//  MastodonStatusPublisher.swift
//  
//
//  Created by MainasuK on 2021-12-1.
//

import os.log
import Foundation
import TwidereCommon
import TwidereCore
import MastodonSDK
import CoreDataStack

public final class MastodonStatusPublisher: NSObject, ProgressReporting {
    
    let logger = Logger(subsystem: "MastodonStatusPublisher", category: "Publisher")
    
    // Input
    
    // author
    public let author: MastodonUser
    // refer
    public let replyTo: ManagedObjectRecord<MastodonStatus>?
    // content warning
    public let isContentWarningComposing: Bool
    public let contentWarning: String
    // status content
    public let content: String
    // media
    public let isMediaSensitive: Bool
    public let attachmentViewModels: [AttachmentViewModel]
    // poll
    public let isPollComposing: Bool
    public let pollOptions: [PollComposeItem.Option]
    public let pollExpireConfiguration: PollComposeItem.ExpireConfiguration
    public let pollMultipleConfiguration: PollComposeItem.MultipleConfiguration
    // visibility
    public let visibility: Mastodon.Entity.Status.Visibility
    
    // Output
    let _progress = Progress()
    public var progress: Progress { _progress }
    @Published var _state: StatusPublisherState = .pending
    public var state: Published<StatusPublisherState>.Publisher { $_state }
    
    public init(
        author: MastodonUser,
        replyTo: ManagedObjectRecord<MastodonStatus>?,
        isContentWarningComposing: Bool,
        contentWarning: String,
        content: String,
        isMediaSensitive: Bool,
        attachmentViewModels: [AttachmentViewModel],
        isPollComposing: Bool,
        pollOptions: [PollComposeItem.Option],
        pollExpireConfiguration: PollComposeItem.ExpireConfiguration,
        pollMultipleConfiguration: PollComposeItem.MultipleConfiguration,
        visibility: Mastodon.Entity.Status.Visibility
    ) {
        self.author = author
        self.replyTo = replyTo
        self.isContentWarningComposing = isContentWarningComposing
        self.contentWarning = contentWarning
        self.content = content
        self.isMediaSensitive = isMediaSensitive
        self.attachmentViewModels = attachmentViewModels
        self.isPollComposing = isPollComposing
        self.pollOptions = pollOptions
        self.pollExpireConfiguration = pollExpireConfiguration
        self.pollMultipleConfiguration = pollMultipleConfiguration
        self.visibility = visibility
    }
    
}

// MARK: - StatusPublisher
extension MastodonStatusPublisher: StatusPublisher {
    
    public func publish(
        api: APIService,
        secret: AppSecret.Secret
    ) async throws -> StatusPublishResult {
        let idempotencyKey = UUID().uuidString
        
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
        
        let _authenticationContext: MastodonAuthenticationContext? = await api.backgroundManagedObjectContext.perform {
            guard let authentication = self.author.mastodonAuthentication else { return nil }
            return MastodonAuthenticationContext(authentication: authentication)
        }
        guard let authenticationContext = _authenticationContext else {
            throw AppError.implicit(.authenticationMissing)
        }
        
        // Task: attachment
        
        let uploadContext = AttachmentViewModel.UploadContext(
            apiService: api,
            authenticationContext: .mastodon(authenticationContext: authenticationContext)
        )
        
        var attachmentIDs: [Mastodon.Entity.Attachment.ID] = []
        for attachmentViewModel in attachmentViewModels {
            // set progress
            progress.addChild(attachmentViewModel.progress, withPendingUnitCount: publishAttachmentTaskWeight)
            // upload media
            do {
                let result = try await attachmentViewModel.upload(context: uploadContext)
                guard case let .mastodon(response) = result else {
                    assertionFailure()
                    continue
                }
                let attachmentID = response.value.id
                attachmentIDs.append(attachmentID)
            } catch {
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): upload attachment fail: \(error.localizedDescription)")
                _state = .failure(error)
                throw error
            }
        }
        
        let pollOptions: [String]? = {
            guard self.isPollComposing else { return nil }
            let options = self.pollOptions.compactMap { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            return options.isEmpty ? nil : options
        }()
        let pollExpiresIn: Int? = {
            guard self.isPollComposing else { return nil }
            guard pollOptions != nil else { return nil }
            return self.pollExpireConfiguration.option.seconds
        }()
        let pollMultiple: Bool? = {
            guard self.isPollComposing else { return nil }
            guard pollOptions != nil else { return nil }
            return self.pollMultipleConfiguration.isMultiple
        }()
        let inReplyToID: Mastodon.Entity.Status.ID? = await api.backgroundManagedObjectContext.perform {
            guard let replyTo = self.replyTo?.object(in: api.backgroundManagedObjectContext) else { return nil }
            return replyTo.id
        }
        
        let query = Mastodon.API.Status.PublishStatusQuery(
            status: content,
            mediaIDs: attachmentIDs.isEmpty ? nil : attachmentIDs,
            pollOptions: pollOptions,
            pollExpiresIn: pollExpiresIn,
            pollMultiple: pollMultiple,
            inReplyToID: inReplyToID,
            sensitive: isMediaSensitive,
            spoilerText: isContentWarningComposing ? contentWarning : nil,
            visibility: visibility,
            idempotencyKey: idempotencyKey
        )
        
        let publishResponse = try await api.publishMastodonStatus(
            query: query,
            mastodonAuthenticationContext: authenticationContext
        )
        progress.completedUnitCount += publishStatusTaskCount
        _state = .success
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): status published: \(publishResponse.value.id)")
        
        return .mastodon(publishResponse)
    }
    
}

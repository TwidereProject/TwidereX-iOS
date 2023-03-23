//
//  DataSourceFacade+Poll.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-10.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwidereCore
import CoreDataStack

extension DataSourceFacade {
    public static func responseToStatusPollUpdate(
        provider: DataSourceProvider & AuthContextProvider,
        status: StatusRecord
    ) async throws {
        let managedObjectContext = provider.context.managedObjectContext
        switch (status, provider.authContext.authenticationContext) {
        case (.twitter(let status), .twitter(let authenticationContext)):
            let _statusID = await managedObjectContext.perform {
                return status.object(in: managedObjectContext)?.id
            }
            guard let statusID = _statusID else {
                assertionFailure()
                return
            }
            _ = try await provider.context.apiService.twitterStatus(
                statusIDs: [statusID],
                authenticationContext: authenticationContext
            )
        case (.mastodon(let status), .mastodon(let authenticationContext)):
            _ = try await provider.context.apiService.viewMastodonStatusPoll(
                status: status,
                authenticationContext: authenticationContext
            )
        default:
            assertionFailure()
        }
    }
}

extension DataSourceFacade {
    public static func responseToStatusPollOption(
        provider: DataSourceProvider,
        target: StatusTarget,
        status: StatusRecord,
        didSelectRowAt index: Int
    ) async {
        let _redirectRecord = await DataSourceFacade.status(
            managedObjectContext: provider.context.managedObjectContext,
            status: status,
            target: target
        )
        guard let redirectRecord = _redirectRecord else { return }
        
        await responseToStatusPollOption(
            provider: provider,
            status: redirectRecord,
            didSelectRowAt: index
        )
    }

    static func responseToStatusPollOption(
        provider: DataSourceProvider,
        status: StatusRecord,
        didSelectRowAt index: Int
    ) async {
        // use same context on UI to make transient property trigger update
        let managedObjectContext = provider.context.managedObjectContext
        
        do {
            try await managedObjectContext.performChanges {
                guard let object = status.object(in: managedObjectContext) else { return }
                switch object {
                case .twitter:
                    assertionFailure("No API from Twitter")
                    break
                case .mastodon(let status):
                    guard let poll = status.poll else {
                        assertionFailure()
                        return
                    }
                    
                    guard !poll.isVoting else {
                        return
                    }
                    guard let option = poll.options.first(where: { $0.index == index }) else {
                        assertionFailure()
                        return
                    }
                    
                    if !poll.multiple {
                        for otherOption in poll.options where option !== otherOption {
                            otherOption.update(isSelected: false)
                        }
                    }
                    
                    let isSelected = option.isSelected
                    option.update(isSelected: !isSelected)

                    option.poll.update(updatedAt: Date())
                }
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
}

extension DataSourceFacade {
    
    static func responseToStatusPollVote(
        provider: DataSourceProvider & AuthContextProvider,
        status: StatusRecord
    ) async throws {
        switch status {
        case .twitter:
            assertionFailure()
        case .mastodon(let record):
            try await responseToStatusPollVote(
                provider: provider,
                status: record
            )
        }
    }
    
    private static func responseToStatusPollVote(
        provider: DataSourceProvider & AuthContextProvider,
        status: ManagedObjectRecord<MastodonStatus>
    ) async throws {
        guard case let .mastodon(authenticationContext) = provider.authContext.authenticationContext else { return }
        
        // should use same context on UI to make transient property trigger update
        let managedObjectContext = provider.context.managedObjectContext
        
        var _error: Error?
        do {
            let choices: [Int] = try await managedObjectContext.performChanges {
                guard let status = status.object(in: managedObjectContext),
                      let poll = status.poll
                else { throw AppError.implicit(.badRequest) }
                
                let choices = poll.options
                    .filter { $0.isSelected }
                    .map { $0.index }
            
                guard !choices.isEmpty else {
                    throw AppError.implicit(.badRequest)
                }
                
                // set isVoting flag
                poll.update(isVoting: true)
                
                return choices.map { Int($0) }
            }
            
            try? await Task.sleep(nanoseconds: 1 * .second) // 1s
            let response = try await provider.context.apiService.voteMastodonStatusPoll(
                status: status,
                choices: choices,
                authenticationContext: authenticationContext
            )
            provider.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): did vote poll: \(response.value.id) with choices: \(choices.debugDescription)")
            
        } catch {
            _error = error
        }
        
        do {
            try await managedObjectContext.performChanges {
                guard let status = status.object(in: managedObjectContext),
                      let poll = status.poll
                else { throw AppError.implicit(.badRequest) }
                
                // remove isVoting flag
                poll.update(isVoting: false)
            }
        } catch {
            assertionFailure(error.localizedDescription)
            _error = error
        }
        
        if let error = _error as? LocalizedError {
            await DataSourceFacade.presentErrorBanner(error: error)
        }
        
        if let error = _error {
            throw error
        }
    }
    
}

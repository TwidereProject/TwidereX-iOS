//
//  DataSourceFacade+Poll.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-10.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwidereUI
import CoreDataStack

extension DataSourceFacade {
    public static func responseToStatusPollOption(
        provider: DataSourceProvider,
        target: StatusTarget,
        status: StatusRecord,
        didSelectRowAt indexPath: IndexPath
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
            didSelectRowAt: indexPath
        )
    }

    static func responseToStatusPollOption(
        provider: DataSourceProvider,
        status: StatusRecord,
        didSelectRowAt indexPath: IndexPath
    ) async {
        // should use same context on UI to make transient property trigger update
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
                    
                    guard let option = poll.options.first(where: { $0.index == indexPath.row }) else {
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
    
    public static func responseToStatusPollOption(
        provider: DataSourceProvider & AuthContextProvider,
        target: StatusTarget,
        status: StatusRecord,
        voteButtonDidPressed button: UIButton
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
            voteButtonDidPressed: button
        )
    }
    
    static func responseToStatusPollOption(
        provider: DataSourceProvider & AuthContextProvider,
        status: StatusRecord,
        voteButtonDidPressed button: UIButton
    ) async {
        do {
            switch status {
            case .twitter:
                assertionFailure()
            case .mastodon(let record):
                try await responseToStatusPollOption(
                    provider: provider,
                    status: record,
                    voteButtonDidPressed: button
                )
            }
        } catch {
            // TODO: handle error
        }
    }
    
    private static func responseToStatusPollOption(
        provider: DataSourceProvider & AuthContextProvider,
        status: ManagedObjectRecord<MastodonStatus>,
        voteButtonDidPressed button: UIButton
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
            
            await Task.sleep(1_000_000_000) // 1s
            let response = try await provider.context.apiService.voteMastodonStatusPoll(
                status: status,
                choices: choices,
                authenticationContext: authenticationContext
            )
            provider.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): did vote poll: \(response.value.id) with choices: \(choices.debugDescription)")
            
        } catch {
            assertionFailure(error.localizedDescription)
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
        
        if let error = _error {
            throw error
        }
    }
    
}

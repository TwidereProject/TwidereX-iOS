//
//  APIService+Status+Poll.swift
//  
//
//  Created by MainasuK on 2021-12-10.
//

import Foundation
import MastodonSDK
import CoreDataStack

extension APIService {
    
    private struct MastodonViewPollContext {
        let pollID: Mastodon.Entity.Poll.ID
    }
    
    public func viewMastodonStatusPoll(
        status: ManagedObjectRecord<MastodonStatus>,
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Poll> {
        let domain = authenticationContext.domain
        let authorization = authenticationContext.authorization
        
        let managedObjectContext = backgroundManagedObjectContext
        let viewContext: MastodonViewPollContext = try await managedObjectContext.perform {
            guard let status = status.object(in: managedObjectContext),
                  let poll = status.poll
            else {
                throw AppError.implicit(.badRequest)
            }
            
            let context = MastodonViewPollContext(
                pollID: poll.id
            )
            
            return context
        }
        
        
        let response = try await Mastodon.API.Poll.poll(
            session: session,
            domain: domain,
            pollID: viewContext.pollID,
            authorization: authorization
        )
        
        do {
            try await managedObjectContext.performChanges {
                let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
                
                _ = Persistence.MastodonPoll.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.MastodonPoll.PersistContext(
                        domain: domain,
                        entity: response.value,
                        me: me,
                        networkDate: response.networkDate
                    )
                )
            }
            
        } catch {
            assertionFailure(error.localizedDescription)
        }
        
        return response
    }
}

extension APIService {
    
    private struct MastodonVotePollContext {
        let pollID: Mastodon.Entity.Poll.ID
        // let choices: [Int]
    }
    
    public func voteMastodonStatusPoll(
        status: ManagedObjectRecord<MastodonStatus>,
        choices: [Int],
        authenticationContext: MastodonAuthenticationContext
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Poll> {
        let domain = authenticationContext.domain
        let authorization = authenticationContext.authorization
        
        let managedObjectContext = backgroundManagedObjectContext
        let voteContext: MastodonVotePollContext = try await managedObjectContext.perform {
            guard let status = status.object(in: managedObjectContext),
                  let poll = status.poll
            else {
                throw AppError.implicit(.badRequest)
            }
            
            let context = MastodonVotePollContext(
                pollID: poll.id
            )
            
            return context
        }
        
        let query = Mastodon.API.Poll.VoteQuery(choices: choices)
        
        let response = try await Mastodon.API.Poll.vote(
            session: session,
            domain: domain,
            pollID: voteContext.pollID,
            query: query,
            authorization: authorization
        )
        
        do {
            try await managedObjectContext.performChanges {
                let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user
                
                _ = Persistence.MastodonPoll.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.MastodonPoll.PersistContext(
                        domain: domain,
                        entity: response.value,
                        me: me,
                        networkDate: response.networkDate
                    )
                )
            }
            
        } catch {
            assertionFailure(error.localizedDescription)
        }
        
        return response
    }
}

//
//  DataSourceFacade+SavedSearch.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-27.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import TwidereCore
import SwiftMessages

extension DataSourceFacade {
    
    @MainActor
    static func coordinateToSearchResult(
        dependency: NeedsDependency & AuthContextProvider & UIViewController,
        savedSearch: SavedSearchRecord
    ) {
        guard let savedResult = savedSearch.object(in: dependency.context.managedObjectContext) else { return }

        let searchResultViewModel = SearchResultViewModel(
            context: dependency.context,
            authContext: dependency.authContext,
            coordinator: dependency.coordinator
        )
        searchResultViewModel.searchText = savedResult.query
        dependency.coordinator.present(
            scene: .searchResult(viewModel: searchResultViewModel),
            from: dependency,
            transition: .modal(animated: true, completion: nil)
        )
    }
    
    @MainActor
    static func coordinateToSearchResult(
        dependency: NeedsDependency & AuthContextProvider & UIViewController,
        trend object: TrendObject
    ) {
        let searchResultViewModel = SearchResultViewModel(
            context: dependency.context,
            authContext: dependency.authContext,
            coordinator: dependency.coordinator
        )
        searchResultViewModel.searchText = object.query
        dependency.coordinator.present(
            scene: .searchResult(viewModel: searchResultViewModel),
            from: dependency,
            transition: .modal(animated: true, completion: nil)
        )
    }
    
    @MainActor
    static func responseToCreateSavedSearch(
        dependency: NeedsDependency,
        searchText: String,
        authenticationContext: AuthenticationContext
    ) async throws {
        let searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchText.isEmpty else { return }
        
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        
        switch authenticationContext {
        case .twitter(let authenticationContext):
            do {
                impactFeedbackGenerator.impactOccurred()
                _ = try await dependency.context.apiService.createTwitterSavedSearch(
                    text: searchText,
                    authenticationContext: authenticationContext
                )
                notificationFeedbackGenerator.notificationOccurred(.success)

            } catch {
                notificationFeedbackGenerator.notificationOccurred(.error)
                throw error
            }
        case .mastodon(let authenticationContext):
            do {
                impactFeedbackGenerator.impactOccurred()
                let managedObjectContext = dependency.context.backgroundManagedObjectContext
                try await managedObjectContext.performChanges {
                    guard let me = authenticationContext.authenticationRecord.object(in: managedObjectContext)?.user else {
                        throw AppError.implicit(.authenticationMissing)
                    }
                    _ = Persistence.MastodonSavedSearch.createOrMerge(
                        in: managedObjectContext,
                        context: Persistence.MastodonSavedSearch.PersistContext(
                            entity: searchText,
                            me: me,
                            networkDate: Date()
                        )
                    )
                }
                notificationFeedbackGenerator.notificationOccurred(.success)

            } catch {
                notificationFeedbackGenerator.notificationOccurred(.error)
                throw error
            }
        }
    }
    
    @MainActor
    static func responseToDeleteSavedSearch(
        dependency: NeedsDependency,
        savedSearch: SavedSearchRecord,
        authenticationContext: AuthenticationContext
    ) async throws {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        
        switch (savedSearch, authenticationContext) {
        case (.twitter(let record), .twitter(let authenticationContext)):
            do {
                impactFeedbackGenerator.impactOccurred()
                _ = try await dependency.context.apiService.destoryTwitterSavedSearch(
                    savedSearch: record,
                    authenticationContext: authenticationContext
                )
                notificationFeedbackGenerator.notificationOccurred(.success)

            } catch {
                SwiftMessages.presentFailureNotification(error: error)
                notificationFeedbackGenerator.notificationOccurred(.error)
                throw error
            }
        case (.mastodon(let record), .mastodon(let authenticationContext)):
            do {
                impactFeedbackGenerator.impactOccurred()
                let managedObjectContext = dependency.context.backgroundManagedObjectContext
                try await managedObjectContext.performChanges {
                    guard let object = record.object(in: managedObjectContext) else { return }
                    managedObjectContext.delete(object)
                }
                notificationFeedbackGenerator.notificationOccurred(.success)

            } catch {
                SwiftMessages.presentFailureNotification(error: error)
                notificationFeedbackGenerator.notificationOccurred(.error)
                throw error
            }
        default:
            assertionFailure()
            return
        }
    }
    
}

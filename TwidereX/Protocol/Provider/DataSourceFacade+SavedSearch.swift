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
        dependency: NeedsDependency & UIViewController,
        savedSearch: SavedSearchRecord
    ) {
        guard let object = savedSearch.object(in: dependency.context.managedObjectContext) else { return }

        switch object {
        case .twitter(let savedResult):
            let searchResultViewModel = SearchResultViewModel(
                context: dependency.context,
                coordinator: dependency.coordinator
            )
            searchResultViewModel.searchText = savedResult.query
            dependency.coordinator.present(
                scene: .searchResult(viewModel: searchResultViewModel),
                from: dependency,
                transition: .modal(animated: true, completion: nil)
            )
        }
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
            assertionFailure("TODO")
            break
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
        default:
            assertionFailure("TODO")
            break
        }
    }
    
}

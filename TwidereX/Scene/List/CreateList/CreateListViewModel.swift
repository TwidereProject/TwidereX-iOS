//
//  CreateListViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-14.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import Combine
import CoreDataStack
import TwidereCore
import TwitterSDK
import MastodonSDK

final class CreateListViewModel: ObservableObject {
    
    let logger = Logger(subsystem: "CreateListViewModel", category: "ViewModel")
    
    // input
    let context: AppContext
    let platform: Platform
    
    @Published var name = ""
    @Published var description = ""
    @Published var isPrivate = false
    
    // output
    @Published var isValid = false
    @Published var isBusy = false
        
    init(
        context: AppContext,
        platform: Platform
    ) {
        self.context = context
        self.platform = platform
        
        $name
            .map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .assign(to: &$isValid)
    }
    
    @MainActor
    func createList() async throws -> APIService.CreateListResponse {
        let _query: APIService.CreateListQuery? = {
            switch platform {
            case .none:
                return nil
            case .twitter:
                return .twitter(query: Twitter.API.V2.List.CreateQuery(
                    name: name,
                    description: description,
                    private: isPrivate
                ))
            case .mastodon:
                return .mastodon(query: Mastodon.API.List.CreateQuery(
                    title: name,
                    repliesPolicy: nil
                ))
            }
        }()
        guard let query = _query,
              let authenticationContext = context.authenticationService.activeAuthenticationContext
        else {
            throw AppError.implicit(.badRequest)
        }
        
        guard !isBusy else {
            throw AppError.implicit(.badRequest)
        }
        isBusy = true
        defer { isBusy = false }
        
        do {
            let response = try await context.apiService.create(
                query: query,
                authenticationContext: authenticationContext
            )
            
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): create list success")
            return response
        } catch {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): create list failure: \(error.localizedDescription)")
            throw error
        }
    }
    
}

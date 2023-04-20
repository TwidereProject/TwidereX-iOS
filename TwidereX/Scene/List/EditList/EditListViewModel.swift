//
//  EditListViewModel.swift
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

final class EditListViewModel: ObservableObject {
    
    let logger = Logger(subsystem: "EditListViewModel", category: "ViewModel")
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let platform: Platform
    let kind: Kind
    
    @Published var name = ""
    @Published var description = ""
    @Published var isPrivate = false
    
    // output
    @Published var isValid = false
    @Published var isBusy = false
        
    init(
        context: AppContext,
        authContext: AuthContext,
        platform: Platform,
        kind: Kind
    ) {
        self.context = context
        self.authContext = authContext
        self.platform = platform
        self.kind = kind
        // end init
        
        switch kind {
        case .create:
            break
        case .edit(let list):
            Task {
                await setupList(list: list)
            }   // end Task
        }
        
        $name
            .map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .assign(to: &$isValid)
    }
}

extension EditListViewModel {
    enum Kind {
        case create
        case edit(list: ListRecord)
        
        var list: ListRecord? {
            switch self {
            case .create:               return nil
            case .edit(let list):       return list
            }
        }
    }
}

extension EditListViewModel {
    
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
        guard let query = _query else {
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
                authenticationContext: authContext.authenticationContext
            )
            
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): create list success")
            return response
        } catch {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): create list failure: \(error.localizedDescription)")
            throw error
        }
    }
    
}

extension EditListViewModel {
    
    private enum ListInfo {
        case twitter(TwitterListInfo)
        case mastodon(MastodonListInfo)
    }
    private struct TwitterListInfo {
        let name: String
        let description: String
        let isPrivate: Bool
    }
    
    private struct MastodonListInfo {
        let name: String
    }
    
    @MainActor
    func setupList(list: ListRecord) async {
        let managedObjectContext = context.managedObjectContext
        let _info: ListInfo? = await managedObjectContext.perform {
            guard let object = list.object(in: managedObjectContext) else { return nil }
            switch object {
            case .twitter(let list):
                return .twitter(.init(
                    name: list.name,
                    description: list.theDescription ?? "",
                    isPrivate: list.private
                ))
            case .mastodon(let list):
                return .mastodon(.init(name: list.title))
            }
        }
        guard let info = _info else { return }
        
        switch info {
        case .twitter(let info):
            self.name = info.name
            self.description = info.description
            self.isPrivate = info.isPrivate
        case .mastodon(let info):
            self.name = info.name
        }
    }
    
    @MainActor
    func updateList() async throws -> APIService.UpdateListResponse {
        guard let list = kind.list else {
            throw AppError.implicit(.badRequest)
        }
        let _query: APIService.UpdateListQuery? = {
            switch list {
            case .twitter:
                return .twitter(query: .init(
                    name: self.name,
                    description: self.description,
                    private: self.isPrivate
                ))
            case .mastodon:
                return .mastodon(query: .init(
                    title: self.name,
                    repliesPolicy: nil
                ))
            }
        }()
        guard let query = _query else {
            throw AppError.implicit(.badRequest)
        }
        
        guard !isBusy else {
            throw AppError.implicit(.badRequest)
        }
        isBusy = true
        defer { isBusy = false }
        
        do {
            let response = try await context.apiService.update(
                list: list,
                query: query,
                authenticationContext: authContext.authenticationContext
            )
            
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update list success")
            return response
        } catch {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update list failure: \(error.localizedDescription)")
            throw error
        }
    }
    
}

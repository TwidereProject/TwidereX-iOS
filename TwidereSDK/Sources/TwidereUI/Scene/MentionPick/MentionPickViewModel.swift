//
//  MentionPickerViewModel.swift
//  
//
//  Created by MainasuK on 2021-11-25.
//

import os.log
import UIKit
import Combine
import AlamofireImage
import TwitterSDK
import TwidereCore

// Twitter only
public final class MentionPickViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let apiService: APIService
    let authenticationService: AuthenticationService
    let primaryItem: Item
    let secondaryItems: [Item]
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<Section, Item>?
    
    init(
        apiService: APIService,
        authenticationService: AuthenticationService,
        primaryItem: Item,
        secondaryItems: [Item]
    ) {
        self.apiService = apiService
        self.authenticationService = authenticationService
        self.primaryItem = primaryItem
        self.secondaryItems = secondaryItems
        
        authenticationService.$activeAuthenticationContext
            .sink { [weak self] authenticationContext in
                guard let self = self else { return }
                switch authenticationContext {
                case .twitter(let twitterAuthenticationContext):
                    Task {
                        try await self.resolveLoadingItems(twitterAuthenticationContext: twitterAuthenticationContext)
                    }
                default:
                    break
                }
            }
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension MentionPickViewModel {
    public enum Section: Hashable, CaseIterable {
        case primary
        case secondary
    }
    
    public enum Item: Hashable {
        case twitterUser(username: String, attribute: Attribute)
    }
}

extension MentionPickViewModel.Item {
    public class Attribute: Hashable {
        
        public let id = UUID()

        public var state: State = .loading
        
        // input
        public var disabled: Bool = false
        public var selected: Bool = true
        
        // output
        public var avatarImageURL: URL?
        public var userID: Twitter.Entity.V2.Tweet.ID?
        public var name: String?
            
        public init(
            disabled: Bool = false,
            selected: Bool = true,
            avatarImageURL: URL? = nil,
            userID: Twitter.Entity.V2.Tweet.ID? = nil,
            name: String? = nil,
            state: State = .loading
        ) {
            self.disabled = disabled
            self.selected = selected
            self.avatarImageURL = avatarImageURL
            self.userID = userID
            self.name = name
            self.state = state
        }
        
        public static func == (lhs: Attribute, rhs: Attribute) -> Bool {
            return lhs.state == rhs.state &&
                lhs.disabled == rhs.disabled &&
                lhs.selected == rhs.selected &&
                lhs.avatarImageURL == rhs.avatarImageURL &&
                lhs.userID == rhs.userID
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

    }
}

extension MentionPickViewModel.Item.Attribute {
    public enum State {
        case loading
        case finish
    }
}

extension MentionPickViewModel {

    func resolveLoadingItems(
        twitterAuthenticationContext: TwitterAuthenticationContext
    ) async throws {
        // FIXME: prefer fetch with userID
        let usernames = secondaryItems
            .compactMap { item -> String? in
                switch item {
                case .twitterUser(let username, let attribute):
                    guard attribute.state == .loading else { return nil }
                    return username
                }
            }
        
        let response = try await apiService.twitterUsers(
            usernames: usernames,
            twitterAuthenticationContext: twitterAuthenticationContext
        )
        let users = response.value.data ?? []

        var items: [Item] = []
        for item in secondaryItems {
            switch item {
            case .twitterUser(let username, let attribute):
                guard let user = users.first(where: { $0.username == username }) else { continue }
                attribute.avatarImageURL = user.avatarImageURL()
                attribute.userID = user.id
                attribute.name = user.name
                attribute.state = .finish
                 
                items.append(item)
            }
        }
        
        guard let diffableDataSource = self.diffableDataSource else { return }
        if !items.isEmpty {
            var snapshot = diffableDataSource.snapshot()
            snapshot.reloadItems(items)
            await diffableDataSource.apply(snapshot)
        }
    }
}

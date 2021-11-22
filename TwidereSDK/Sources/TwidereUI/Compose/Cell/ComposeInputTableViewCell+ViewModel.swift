//
//  ComposeInputTableViewCell.swift
//  
//
//  Created by MainasuK on 2021/11/22.
//

import UIKit
import SwiftUI
import Combine
import TwidereCore
import CoreDataStack

extension ComposeInputTableViewCell {
    public class ViewModel {
        var configureDisposeBag = Set<AnyCancellable>()
        var bindDisposeBag = Set<AnyCancellable>()
        
        @Published var avatarImageURL: URL?
    }
}

extension ComposeInputTableViewCell.ViewModel {
    public func bind(cell: ComposeInputTableViewCell) {
        // avatar
        $avatarImageURL
            .removeDuplicates()
            .sink { imageURL in
                cell.avatarView.avatarButton.avatarImageView.setImage(
                    url: imageURL,
                    placeholder: .placeholder(color: .systemFill),
                    scaleToSize: nil
                )
            }
            .store(in: &bindDisposeBag)
    }
}

extension ComposeInputTableViewCell {
    func configure(user: UserObject?) {
        // reset
        viewModel.configureDisposeBag.removeAll()
        
        guard let user = user else { return }
        
        switch user {
        case .twitter(let object):
            configure(twitterUser: object)
        case .mastodon(let object):
            configure(mastodonUser: object)
        }
    }
}

// MARK: - Twitter
extension ComposeInputTableViewCell {
    private func configure(twitterUser user: TwitterUser) {
        // avatar
        user.publisher(for: \.profileImageURL)
            .map { _ in user.avatarImageURL(size: .original) }
            .assign(to: \.avatarImageURL, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
    }
}

// MARK: - Mastodon
extension ComposeInputTableViewCell {
    private func configure(mastodonUser user: MastodonUser) {
        
    }
}

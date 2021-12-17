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
        var observations = Set<NSKeyValueObservation>()
        
        @Published var avatarImageURL: URL?
        @Published var isContentWarningDisplay: Bool = false
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
        UserDefaults.shared
            .observe(\.avatarStyle, options: [.initial, .new]) { defaults, _ in
                let avatarStyle = defaults.avatarStyle
                let animator = UIViewPropertyAnimator(duration: 0.3, timingParameters: UISpringTimingParameters())
                animator.addAnimations { [weak cell] in
                    guard let cell = cell else { return }
                    switch avatarStyle {
                    case .circle:
                        cell.avatarView.avatarStyle = .circle
                    case .roundedSquare:
                        cell.avatarView.avatarStyle = .roundedRect
                    }
                }
                animator.startAnimation()
            }
            .store(in: &observations)
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
        // avatar
        user.publisher(for: \.avatar)
            .map { url in url.flatMap { URL(string: $0) } }
            .assign(to: \.avatarImageURL, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
    }
}

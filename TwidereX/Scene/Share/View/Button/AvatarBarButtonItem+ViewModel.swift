//
//  AvatarBarButtonItem+ViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-2.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import TwidereCore
import CoreDataStack

extension AvatarBarButtonItem {
    public class ViewModel: ObservableObject {
        var configureDisposeBag = Set<AnyCancellable>()
        var bindDisposeBag = Set<AnyCancellable>()
        var observations = Set<NSKeyValueObservation>()
        
        @Published var avatarURL: URL?
    }
}

extension AvatarBarButtonItem.ViewModel {
    func bind(view: AvatarBarButtonItem) {
        // avatar
        $avatarURL
            .sink { avatarURL in
                let configuration = AvatarImageView.Configuration(url: avatarURL)
                view.avatarButton.avatarImageView.configure(configuration: configuration)
            }
            .store(in: &bindDisposeBag)
        UserDefaults.shared
            .observe(\.avatarStyle, options: [.initial, .new]) { defaults, _ in
                let avatarStyle = defaults.avatarStyle
                let animator = UIViewPropertyAnimator(duration: 0.3, timingParameters: UISpringTimingParameters())
                animator.addAnimations { [weak view] in
                    guard let view = view else { return }
                    switch avatarStyle {
                    case .circle:
                        view.avatarButton.avatarImageView.configure(cornerConfiguration: .init(corner: .circle))
                    case .roundedSquare:
                        view.avatarButton.avatarImageView.configure(cornerConfiguration: .init(corner: .scale(ratio: 4)))
                    }
                }
                animator.startAnimation()
            }
            .store(in: &observations)
    }
}

extension AvatarBarButtonItem {
    func configure(user: UserObject?) {
        switch user {
        case .twitter(let object):
            configure(twitterUser: object)
        case .mastodon(let object):
            configure(mastodonUser: object)
        case .none:
            reset()
        }
    }

}

extension AvatarBarButtonItem {
    
    func reset() {
        viewModel.avatarURL = nil
    }
    
    func configure(twitterUser user: TwitterUser) {
        // avatar
        user.publisher(for: \.profileImageURL)
            .map { _ in user.avatarImageURL() }
            .assign(to: \.avatarURL, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
    }
    
    func configure(mastodonUser user: MastodonUser) {
        // avatar
        user.publisher(for: \.avatar)
            .map { avatar in avatar.flatMap { URL(string: $0) } }
            .assign(to: \.avatarURL, on: viewModel)
            .store(in: &viewModel.configureDisposeBag)
    }

}

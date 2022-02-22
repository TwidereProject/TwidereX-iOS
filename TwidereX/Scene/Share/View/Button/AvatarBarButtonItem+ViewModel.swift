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
import TwidereUI

extension AvatarBarButtonItem {
    public class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        var observations = Set<NSKeyValueObservation>()
        
        @Published var avatarURL: URL?
        
        @Published var avatarStyle: UserDefaults.AvatarStyle = UserDefaults.shared.avatarStyle
        
        init() {
            UserDefaults.shared
                .observe(\.avatarStyle, options: [.initial, .new]) { defaults, _ in
                    self.avatarStyle = defaults.avatarStyle
                }
                .store(in: &observations)
        }
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
            .store(in: &disposeBag)
        
        func cornerConfiguration(avatarStyle: UserDefaults.AvatarStyle) -> AvatarImageView.CornerConfiguration {
            switch avatarStyle {
            case .circle:
                return .init(corner: .circle)
            case .roundedSquare:
                return .init(corner: .scale(ratio: 4))
            }
        }
        
        view.avatarButton.avatarImageView.configure(
            cornerConfiguration: cornerConfiguration(avatarStyle: avatarStyle)
        )
        $avatarStyle
            .removeDuplicates()
            .sink { avatarStyle in
                let cornerConfiguration = cornerConfiguration(avatarStyle: avatarStyle)
                
                let animator = UIViewPropertyAnimator(duration: 0.3, timingParameters: UISpringTimingParameters())
                animator.addAnimations { [weak view] in
                    guard let view = view else { return }
                    view.avatarButton.avatarImageView.configure(cornerConfiguration: cornerConfiguration)
                }
                animator.startAnimation()
            }
            .store(in: &disposeBag)
    }
}

extension AvatarBarButtonItem {
    func configure(user: UserObject?) {
        reset()
        
        switch user {
        case .twitter(let object):
            configure(twitterUser: object)
        case .mastodon(let object):
            configure(mastodonUser: object)
        case .none:
            break
        }
    }

}

extension AvatarBarButtonItem {
    
    func reset() {
        viewModel.avatarURL = nil
        disposeBag.removeAll()
    }
    
    func configure(twitterUser user: TwitterUser) {
        guard user.managedObjectContext != nil else {
            return
        }
        
        // avatar
        user.publisher(for: \.profileImageURL)
            .map { _ in user.avatarImageURL() }
            .assign(to: \.avatarURL, on: viewModel)
            .store(in: &disposeBag)
    }
    
    func configure(mastodonUser user: MastodonUser) {
        guard user.managedObjectContext != nil else {
            return
        }
        
        // avatar
        user.publisher(for: \.avatar)
            .map { avatar in avatar.flatMap { URL(string: $0) } }
            .assign(to: \.avatarURL, on: viewModel)
            .store(in: &disposeBag)
    }

}

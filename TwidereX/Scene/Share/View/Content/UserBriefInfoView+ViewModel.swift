//
//  UserBriefInfoView+ViewModel.swift
//  UserBriefInfoView+ViewModel
//
//  Created by Cirno MainasuK on 2021-8-27.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import SwiftUI
import CoreDataStack
import Meta

extension UserBriefInfoView {
    final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        
        @Published var platform: Platform = .none
        
        @Published var avatarImageURL: URL?
        @Published var headlineMetaContent: MetaContent?
        @Published var subheadlineText: String?
    }
}

extension UserBriefInfoView.ViewModel {
    func bind(userBriefInfoView: UserBriefInfoView) {
        // avatar
        $avatarImageURL
            .sink { url in
                let configuration = AvatarImageView.Configuration(url: url)
                userBriefInfoView.avatarImageView.configure(configuration: configuration)
            }
            .store(in: &disposeBag)
        // badge
        $platform
            .sink { platform in
                switch platform {
                case .twitter:
                    userBriefInfoView.badgeImageView.image = Asset.Badge.circleTwitter.image
                    userBriefInfoView.setBadgeDisplay()
                case .mastodon:
                    userBriefInfoView.badgeImageView.image = Asset.Badge.circleMastodon.image
                    userBriefInfoView.setBadgeDisplay()
                case .none:
                    break
                }
            }
            .store(in: &disposeBag)
        // headline
        $headlineMetaContent
            .sink { content in
                guard let content = content else {
                    userBriefInfoView.headlineLabel.reset()
                    return
                }
                userBriefInfoView.headlineLabel.configure(content: content)
            }
            .store(in: &disposeBag)
        // subheadline
        $subheadlineText
            .assign(to: \.text, on: userBriefInfoView.subheadlineLabel)
            .store(in: &disposeBag)
    }
    
}

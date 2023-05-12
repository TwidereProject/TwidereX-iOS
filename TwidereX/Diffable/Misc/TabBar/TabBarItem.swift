//
//  TabBarItem.swift
//  TwidereX
//
//  Created by MainasuK on 2022-5-5.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit
import TwidereAsset
import TwidereLocalization

enum TabBarItem: Int, Hashable {
    case home
    case homeList
    case notification
    case search
    case me
    case local              // Mastodon only
    case federated          // Mastodon only
    case messages
    case likes
    case history
    case lists
    case trends
    case drafts
    case settings
}

extension TabBarItem {
    
    var tag: Int {
        return rawValue
    }
    
    var title: String {
        switch self {
        case .home:             return L10n.Scene.Timeline.title
        case .homeList:         return L10n.Scene.Timeline.title
        case .notification:     return L10n.Scene.Notification.title
        case .search:           return L10n.Scene.Search.title
        case .me:               return L10n.Scene.Profile.title
        case .local:            return L10n.Scene.Local.title
        case .federated:        return L10n.Scene.Federated.title
        case .messages:         return L10n.Scene.Messages.title
        case .likes:            return L10n.Scene.Likes.title
        case .history:          return L10n.Scene.History.title
        case .lists:            return L10n.Scene.Lists.title
        case .trends:           return L10n.Scene.Trends.title
        case .drafts:           return L10n.Scene.Drafts.title
        case .settings:         return L10n.Scene.Settings.title
        }
    }
    
    var image: UIImage {
        switch self {
        case .home:             return Asset.ObjectTools.house.image.withRenderingMode(.alwaysTemplate)
        case .homeList:         return Asset.ObjectTools.house.image.withRenderingMode(.alwaysTemplate)
        case .notification:     return Asset.ObjectTools.bell.image.withRenderingMode(.alwaysTemplate)
        case .search:           return Asset.ObjectTools.magnifyingglass.image.withRenderingMode(.alwaysTemplate)
        case .me:               return Asset.Human.person.image.withRenderingMode(.alwaysTemplate)
        case .local:            return Asset.Human.person2.image.withRenderingMode(.alwaysTemplate)
        case .federated:        return Asset.ObjectTools.globe.image.withRenderingMode(.alwaysTemplate)
        case .messages:         return Asset.Communication.mail.image.withRenderingMode(.alwaysTemplate)
        case .likes:            return Asset.Health.heart.image.withRenderingMode(.alwaysTemplate)
        case .history:          return Asset.Arrows.clockArrowCirclepath.image.withRenderingMode(.alwaysTemplate)
        case .lists:            return Asset.TextFormatting.listBullet.image.withRenderingMode(.alwaysTemplate)
        case .trends:           return Asset.Arrows.trendingUp.image.withRenderingMode(.alwaysTemplate)
        case .drafts:           return Asset.ObjectTools.note.image.withRenderingMode(.alwaysTemplate)
        case .settings:         return Asset.Editing.sliderHorizontal3.image.withRenderingMode(.alwaysTemplate)
        }
    }
    
    var altImage: UIImage {
        switch self {
        case .notification:     return Asset.ObjectTools.bellRinging.image.withRenderingMode(.alwaysTemplate)
        default:                return image
        }
    }
    
    var largeImage: UIImage {
        return image.resized(size: CGSize(width: 80, height: 80))
    }
    
}

extension TabBarItem {
    func viewController(context: AppContext, coordinator: SceneCoordinator, authContext: AuthContext) -> UIViewController {
        let viewController: UIViewController
        switch self {
        case .home:
            let _viewController = HomeTimelineViewController()
            _viewController.viewModel = HomeTimelineViewModel(context: context, authContext: authContext)
            viewController = _viewController
        case .homeList:
            let _viewController = HomeListStatusTimelineViewController()
            _viewController.viewModel = HomeListStatusTimelineViewModel(context: context, authContext: authContext)
            viewController = _viewController
        case .notification:
            let _viewController = NotificationViewController()
            _viewController.viewModel = NotificationViewModel(context: context, authContext: authContext, coordinator: coordinator)
            viewController = _viewController
        case .search:
            let _viewController = SearchViewController()
            _viewController.viewModel = SearchViewModel(context: context, authContext: authContext)
            viewController = _viewController
        case .me:
            let _viewController = ProfileViewController()
            let profileViewModel = MeProfileViewModel(context: context, authContext: authContext)
            _viewController.viewModel = profileViewModel
            viewController = _viewController
        case .local:
            let _viewController = FederatedTimelineViewController()
            _viewController.viewModel = FederatedTimelineViewModel(context: context, authContext: authContext, isLocal: true)
            viewController = _viewController
        case .federated:
            let _viewController = FederatedTimelineViewController()
            _viewController.viewModel = FederatedTimelineViewModel(context: context, authContext: authContext, isLocal: false)
            viewController = _viewController
        case .messages:
            fatalError()
        case .likes:
            let _viewController = UserLikeTimelineViewController()
            _viewController.viewModel = UserLikeTimelineViewModel(
                context: context,
                authContext: authContext,
                timelineContext: .init(
                    timelineKind: .like,
                    protected: {
                        guard let user = authContext.authenticationContext.user(in: context.managedObjectContext) else { return false }
                        return user.protected
                    }(),
                    userIdentifier: authContext.authenticationContext.userIdentifier
                )
            )
            viewController = _viewController
        case .history:
            let _viewController = HistoryViewController()
            _viewController.viewModel = HistoryViewModel(
                context: context,
                coordinator: coordinator,
                authContext: authContext
            )
            viewController = _viewController
        case .lists:
            guard let me = authContext.authenticationContext.user(in: context.managedObjectContext)?.asRecord else {
                return AdaptiveStatusBarStyleNavigationController(rootViewController: UIViewController())
            }
            let _viewController = CompositeListViewController()
            _viewController.viewModel = CompositeListViewModel(context: context, authContext: authContext, kind: .lists(me))
            viewController = _viewController
        case .trends:
            fatalError()
        case .drafts:
            fatalError()
        case .settings:
            fatalError()
        }
        viewController.title = self.title
        if let viewController = viewController as? NeedsDependency {
            viewController.context = context
            viewController.coordinator = coordinator
        }
        return viewController
    }
}

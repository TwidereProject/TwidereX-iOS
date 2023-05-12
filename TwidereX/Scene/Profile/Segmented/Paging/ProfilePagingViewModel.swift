//
//  ProfilePagingViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import os.log
import UIKit
import Combine
import TabBarPager

final class ProfilePagingViewModel: NSObject {
    
    // input
    let context: AppContext
    let authContext: AuthContext
    let displayLikeTimeline: Bool
    
    // output
    let userTimelineViewController: UserTimelineViewController
    let mediaTimelineViewController: UserMediaTimelineViewController
    let likeTimelineViewController: UserLikeTimelineViewController?
    
    init(
        context: AppContext,
        authContext: AuthContext,
        coordinator: SceneCoordinator,
        displayLikeTimeline: Bool,
        protected: Published<Bool?>.Publisher?,
        userIdentifier: Published<UserIdentifier?>.Publisher?
    ) {
        self.context = context
        self.authContext = authContext
        self.displayLikeTimeline = displayLikeTimeline
        self.userTimelineViewController = {
            let viewController = UserTimelineViewController()
            let viewModel = UserTimelineViewModel(
                context: context,
                authContext: authContext,
                timelineContext: .init(
                    timelineKind: .status,
                    protected: protected,
                    userIdentifier: userIdentifier
                )
            )
            viewModel.isFloatyButtonDisplay = false
            viewController.context = context
            viewController.coordinator = coordinator
            viewController.viewModel = viewModel
            return viewController
        }()
        self.mediaTimelineViewController = {
            let viewController = UserMediaTimelineViewController()
            let viewModel = UserMediaTimelineViewModel(
                context: context,
                authContext: authContext,
                timelineContext: .init(
                    timelineKind: .media,
                    protected: protected,
                    userIdentifier: userIdentifier
                )
            )
            viewModel.isFloatyButtonDisplay = false
            viewController.context = context
            viewController.coordinator = coordinator
            viewController.viewModel = viewModel
            return viewController
        }()
        self.likeTimelineViewController = {
            // switch authContext.authenticationContext {
            // case .twitter:  return nil
            // default:        break
            // }
            let viewController = UserTimelineViewController()
            let viewModel = UserTimelineViewModel(
                context: context,
                authContext: authContext,
                timelineContext: .init(
                    timelineKind: .like,
                    protected: protected,
                    userIdentifier: userIdentifier
                )
            )
            viewModel.isFloatyButtonDisplay = false
            viewController.context = context
            viewController.coordinator = coordinator
            viewController.viewModel = viewModel
            return viewController
        }()
        super.init()
        // end init
    }
    
    var viewControllers: [UIViewController & TabBarPage] {
        var viewControllers: [UIViewController & TabBarPage] = [
            userTimelineViewController,
            mediaTimelineViewController,
        ]
        if let likeTimelineViewController = likeTimelineViewController {
            viewControllers.append(likeTimelineViewController)
        }
        return viewControllers
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

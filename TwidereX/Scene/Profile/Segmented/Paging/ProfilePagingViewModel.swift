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
    @Published var displayLikeTimeline: Bool = true
    
    // output
    let homeTimelineViewController = UserTimelineViewController()
    let mediaTimelineViewController = UserMediaTimelineViewController()
    let likeTimelineViewController = UserLikeTimelineViewController()
    
    init(
        userTimelineViewModel: UserTimelineViewModel,
        userMediaTimelineViewModel: UserMediaTimelineViewModel,
        userLikeTimelineViewModel: UserLikeTimelineViewModel
    ) {
        homeTimelineViewController.viewModel = userTimelineViewModel
        mediaTimelineViewController.viewModel = userMediaTimelineViewModel
        likeTimelineViewController.viewModel = userLikeTimelineViewModel
        super.init()
    }
    
    var viewControllers: [UIViewController & TabBarPage] {
        return [
            homeTimelineViewController,
            mediaTimelineViewController,
            likeTimelineViewController,
        ]
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

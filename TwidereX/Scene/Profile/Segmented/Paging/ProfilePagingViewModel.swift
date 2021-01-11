//
//  ProfilePagingViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import os.log
import UIKit
import Pageboy
import Tabman

final class ProfilePagingViewModel: NSObject {
    
    let profileTweetPostTimelineViewController = UserTimelineViewController()
    let profileMediaPostTimelineViewController = UserMediaTimelineViewController()
    let profileLikesPostTimelineViewController = UserLikeTimelineViewController()
    
    init(
        userTimelineViewModel: UserTimelineViewModel,
        userMediaTimelineViewModel: UserMediaTimelineViewModel,
        userLikeTimelineViewModel: UserLikeTimelineViewModel
    ) {
        profileTweetPostTimelineViewController.viewModel = userTimelineViewModel
        profileMediaPostTimelineViewController.viewModel = userMediaTimelineViewModel
        profileLikesPostTimelineViewController.viewModel = userLikeTimelineViewModel
        super.init()
    }
    
    var viewControllers: [ScrollViewContainer] {
        return [
            profileTweetPostTimelineViewController,
            profileMediaPostTimelineViewController,
            profileLikesPostTimelineViewController,
        ]
    }
    
    let barItems: [TMBarItemable] = {
        let items = [
            TMBarItem(image: Asset.TextFormatting.capitalFloatLeft.image.withRenderingMode(.alwaysTemplate)),
            TMBarItem(image: Asset.ObjectTools.photo.image.withRenderingMode(.alwaysTemplate)),
            TMBarItem(image: Asset.Health.heartFill.image.withRenderingMode(.alwaysTemplate)),
        ]
        return items
    }()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

// MARK: - PageboyViewControllerDataSource
extension ProfilePagingViewModel: PageboyViewControllerDataSource {
    
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }
    
    func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        return viewControllers[index]
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return .first
    }
    
}

// MARK: - TMBarDataSource
extension ProfilePagingViewModel: TMBarDataSource {
    
    func barItem(for bar: TMBar, at index: Int) -> TMBarItemable {
        return barItems[index]
    }

}

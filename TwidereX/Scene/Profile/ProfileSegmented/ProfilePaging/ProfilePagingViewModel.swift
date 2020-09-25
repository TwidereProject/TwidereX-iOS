//
//  ProfilePagingViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import UIKit
import Pageboy
import Tabman
final class ProfilePagingViewModel: NSObject {
    
    let profileTweetPostTimelineViewController = ProfilePostTimelineViewController()
    let profileMediaPostTimelineViewController = ProfilePostTimelineViewController()
    let profileLikesPostTimelineViewController = ProfilePostTimelineViewController()
    
    override init() {
        super.init()
        
        for viewController in viewControllers {
            viewController.view.preservesSuperviewLayoutMargins = true
            viewController.view.insetsLayoutMarginsFromSafeArea = true
        }
    }
    
    var viewControllers: [ProfilePostTimelineViewController] {
        return [
            profileTweetPostTimelineViewController,
            profileMediaPostTimelineViewController,
            profileLikesPostTimelineViewController,
        ]
    }
    
    var barItems: [TMBarItem] {
        return [
            TMBarItem(title: "Tweets"),
            TMBarItem(title: "Medias"),
            TMBarItem(title: "Likes"),
        ]
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

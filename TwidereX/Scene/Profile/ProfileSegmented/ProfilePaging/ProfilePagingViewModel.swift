//
//  ProfilePagingViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import UIKit
import Pageboy

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
    
    var viewControllers: [UIViewController] {
        return [
            profileTweetPostTimelineViewController,
            profileMediaPostTimelineViewController,
            profileLikesPostTimelineViewController,
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

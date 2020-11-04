//
//  ProfilePagingViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import os.log
import UIKit
import Pageboy
import Tabman

protocol ProfilePagingViewControllerDelegate: class {
    func profilePagingViewController(_ viewController: ProfilePagingViewController, didScrollToPostTimelineViewController postTimelineViewController: CustomScrollViewContainerController, atIndex index: Int)
}

final class ProfilePagingViewController: TabmanViewController {
    
    weak var pagingDelegate: ProfilePagingViewControllerDelegate?
    var viewModel: ProfilePagingViewModel!
    
    
    // MARK: - PageboyViewControllerDelegate
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController, didScrollToPageAt index: TabmanViewController.PageIndex, direction: PageboyViewController.NavigationDirection, animated: Bool) {
        super.pageboyViewController(pageboyViewController, didScrollToPageAt: index, direction: direction, animated: animated)
        
        let viewController = viewModel.viewControllers[index]
        pagingDelegate?.profilePagingViewController(self, didScrollToPostTimelineViewController: viewController, atIndex: index)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ProfilePagingViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = viewModel
    }

}

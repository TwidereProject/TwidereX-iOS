//
//  ProfilePagingViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import UIKit
import Pageboy
import Tabman

protocol ProfilePagingViewControllerDelegate: class {
    func profilePagingViewController(_ viewController: ProfilePagingViewController, didScrollToPostTimelineViewController postTimelineViewController: CustomTableViewController, atIndex index: Int)
}

final class ProfilePagingViewController: TabmanViewController {
    
    weak var pagingDelegate: ProfilePagingViewControllerDelegate?
    var viewModel: ProfilePagingViewModel!
    
    
    // MARK: - PageboyViewControllerDelegate
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController, didScrollToPageAt index: TabmanViewController.PageIndex, direction: PageboyViewController.NavigationDirection, animated: Bool) {
        let viewController = viewModel.viewControllers[index]
        pagingDelegate?.profilePagingViewController(self, didScrollToPostTimelineViewController: viewController, atIndex: index)
    }
    
}

extension ProfilePagingViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = viewModel
    }

}

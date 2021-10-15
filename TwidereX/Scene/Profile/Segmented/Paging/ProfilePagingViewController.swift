//
//  ProfilePagingViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import os.log
import UIKit
import XLPagerTabStrip
import TabBarPager

protocol ProfilePagingViewControllerDelegate: AnyObject {
    func profilePagingViewController(_ viewController: ProfilePagingViewController, didScrollToPostCustomScrollViewContainerController customScrollViewContainerController: ScrollViewContainer, atIndex index: Int)
}

final class ProfilePagingViewController: ButtonBarPagerTabStripViewController, TabBarPageViewController {

    weak var tabBarPageViewDelegate: TabBarPageViewDelegate?
    weak var pagingDelegate: ProfilePagingViewControllerDelegate?
    
    var viewModel: ProfilePagingViewModel!
    
    // MARK: - PageboyViewControllerDelegate
    
    var currentPage: TabBarPage? {
        return viewModel.viewControllers[currentIndex]
    }
    
    var currentPageIndex: Int? {
        currentIndex
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return viewModel.viewControllers
    }
    
    override func updateIndicator(for viewController: PagerTabStripViewController, fromIndex: Int, toIndex: Int, withProgressPercentage progressPercentage: CGFloat, indexWasChanged: Bool) {
        super.updateIndicator(for: viewController, fromIndex: fromIndex, toIndex: toIndex, withProgressPercentage: progressPercentage, indexWasChanged: indexWasChanged)
        
        guard indexWasChanged else { return }
        let page = viewModel.viewControllers[toIndex]
        tabBarPageViewDelegate?.pageViewController(self, didPresentingTabBarPage: page, at: toIndex)
    }
    
//    override func pageboyViewController(_ pageboyViewController: PageboyViewController, didScrollTo position: CGPoint, direction: PageboyViewController.NavigationDirection, animated: Bool) {
//        super.pageboyViewController(pageboyViewController, didScrollTo: position, direction: direction, animated: animated)
//
//        // Fix the SDK bug for table view get row selected during swipe but cancel paging
//        guard let viewController = pageboyViewController.currentViewController as? TabBarPage else {
//            assertionFailure()
//            return
//        }
//        if let tableView = viewController.pageScrollView as? UITableView {
//            for cell in tableView.visibleCells {
//                cell.setHighlighted(false, animated: false)
//            }
//        }
//    }
//
//    override func pageboyViewController(_ pageboyViewController: PageboyViewController, didScrollToPageAt index: TabmanViewController.PageIndex, direction: PageboyViewController.NavigationDirection, animated: Bool) {
//        super.pageboyViewController(pageboyViewController, didScrollToPageAt: index, direction: direction, animated: animated)
//
//        let viewController = viewModel.viewControllers[index]
//        tabBarPageViewDelegate?.pageViewController(self, tabBarPage: viewController, at: index)
//        pagingDelegate?.profilePagingViewController(self, didScrollToPostCustomScrollViewContainerController: viewController, atIndex: index)
//    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ProfilePagingViewController {
    
    override func viewDidLoad() {
        // configure style before viewDidLoad
        settings.style.buttonBarBackgroundColor = .systemBackground
        settings.style.buttonBarItemBackgroundColor = .systemBackground
        settings.style.buttonBarItemsShouldFillAvailableWidth = true
        settings.style.selectedBarHeight = 3
        settings.style.selectedBarBackgroundColor = .systemBlue
        changeCurrentIndexProgressive = { [weak self] (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            oldCell?.imageView.tintColor = .secondaryLabel
            newCell?.imageView.tintColor = .systemBlue
        }
        
        super.viewDidLoad()
        
        
    }

}

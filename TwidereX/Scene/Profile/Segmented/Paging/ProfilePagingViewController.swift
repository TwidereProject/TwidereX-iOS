//
//  ProfilePagingViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import os.log
import UIKit
import Combine
import XLPagerTabStrip
import TabBarPager
import TwidereAsset

protocol ProfilePagingViewControllerDelegate: AnyObject {
    func profilePagingViewController(_ viewController: ProfilePagingViewController, didScrollToPostCustomScrollViewContainerController customScrollViewContainerController: ScrollViewContainer, atIndex index: Int)
}

final class ProfilePagingViewController: ButtonBarPagerTabStripViewController, TabBarPageViewController {

    weak var tabBarPageViewDelegate: TabBarPageViewDelegate?
    weak var pagingDelegate: ProfilePagingViewControllerDelegate?
    
    var disposeBag = Set<AnyCancellable>()
    var viewModel: ProfilePagingViewModel!
    
    // MARK: - TabBarPageViewController
    
    var currentPage: TabBarPage? {
        return viewModel.viewControllers[currentIndex]
    }
    
    var currentPageIndex: Int? {
        currentIndex
    }
    
    // MARK: - ButtonBarPagerTabStripViewController
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        if viewModel.displayLikeTimeline {
            return viewModel.viewControllers
        } else {
            return Array(viewModel.viewControllers.prefix(2))
        }
    }
    
    override func updateIndicator(for viewController: PagerTabStripViewController, fromIndex: Int, toIndex: Int, withProgressPercentage progressPercentage: CGFloat, indexWasChanged: Bool) {
        super.updateIndicator(for: viewController, fromIndex: fromIndex, toIndex: toIndex, withProgressPercentage: progressPercentage, indexWasChanged: indexWasChanged)
        
        guard indexWasChanged else { return }
        let page = viewModel.viewControllers[toIndex]
        tabBarPageViewDelegate?.pageViewController(self, didPresentingTabBarPage: page, at: toIndex)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ProfilePagingViewController {
    
    override func viewDidLoad() {
        // configure style before viewDidLoad
        settings.style.buttonBarBackgroundColor = .clear
        settings.style.buttonBarItemBackgroundColor = .clear
        settings.style.buttonBarItemsShouldFillAvailableWidth = true
        settings.style.selectedBarHeight = 3
        settings.style.selectedBarBackgroundColor = .red
        changeCurrentIndexProgressive = { [weak self] (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard let _ = self else { return }
            guard changeCurrentIndex == true else { return }
            oldCell?.imageView.contentMode = .center
            newCell?.imageView.contentMode = .center
            
            oldCell?.imageView.tintColor = .secondaryLabel
            newCell?.imageView.tintColor = ThemeService.shared.theme.highlight
        }
        
        super.viewDidLoad()
        
        ThemeService.shared.$theme
            .map { $0.highlight }
            .assign(to: \.settings.style.selectedBarBackgroundColor, on: self)
            .store(in: &disposeBag)
        
        let separatorLine = SeparatorLineView()
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: buttonBarView.frameLayoutGuide.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: buttonBarView.frameLayoutGuide.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: buttonBarView.frameLayoutGuide.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: buttonBarView)).priority(.required - 1),
        ])
    }

}

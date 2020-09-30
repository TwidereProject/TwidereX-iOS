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

protocol CustomTableViewController: UIViewController {
    var tableView: UITableView { get }
}

class StubTableViewController: UIViewController, CustomTableViewController {
    var tableView = UITableView()
}

final class ProfilePagingViewModel: NSObject {
    
    let profileTweetPostTimelineViewController = UserTimelineViewController()
    let profileMediaPostTimelineViewController = StubTableViewController()
    let profileLikesPostTimelineViewController = StubTableViewController()
    
    init(userTimelineViewModel viewModel: UserTimelineViewModel) {
        profileTweetPostTimelineViewController.viewModel = viewModel
//        profileMediaPostTimelineViewController.viewModel = viewModel
//        profileLikesPostTimelineViewController.viewModel = viewModel
        super.init()
    }
    
    var viewControllers: [CustomTableViewController] {
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

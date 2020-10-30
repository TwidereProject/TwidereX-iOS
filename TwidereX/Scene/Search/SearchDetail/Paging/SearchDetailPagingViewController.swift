//
//  SearchDetailPagingViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-28.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Pageboy
import Tabman

protocol SearchDetailPagingViewControllerDelegate: class {
    func searchDetailPagingViewController(_ pagingViewController: SearchDetailPagingViewController, didScrollToViewController viewController: UIViewController, atIndex index: Int)
}

final class SearchDetailPagingViewController: TabmanViewController {
    
    weak var pagingDelegate: SearchDetailPagingViewControllerDelegate?
    var viewModel: SearchDetailPagingViewModel!
    
    override func pageboyViewController(_ pageboyViewController: PageboyViewController, didScrollToPageAt index: TabmanViewController.PageIndex, direction: PageboyViewController.NavigationDirection, animated: Bool) {
        super.pageboyViewController(pageboyViewController, didScrollToPageAt: index, direction: direction, animated: animated)
        
        let viewController = viewModel.viewControllers[index]
        pagingDelegate?.searchDetailPagingViewController(self, didScrollToViewController: viewController, atIndex: index)
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension SearchDetailPagingViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = viewModel
    }
    
}

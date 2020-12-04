//
//  SearchDetailPagingViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-28.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import Pageboy
import Tabman

final class SearchDetailPagingViewModel: NSObject {
    
    let searchTimelineViewController = SearchTimelineViewController()
    let searchMediaViewController = SearchMediaViewController()
    let searchUserViewController = SearchUserViewController()
    
    var viewControllers: [UIViewController] {
        return [
            searchTimelineViewController,
            searchMediaViewController,
            searchUserViewController,
        ]
    }
    
    let barItems: [TMBarItemable] = {
        let items = [
            TMBarItem(title: L10n.Scene.Search.Tabs.tweets),
            TMBarItem(title: L10n.Scene.Search.Tabs.media),
            TMBarItem(title: L10n.Scene.Search.Tabs.users),
        ]
        return items
    }()
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let searchText = CurrentValueSubject<String, Never>("")
    var searchActionPublisher = PassthroughSubject<Void, Never>()
    
    init(context: AppContext, coordinator: SceneCoordinator) {
        searchTimelineViewController.context = context
        searchTimelineViewController.coordinator = coordinator
        searchTimelineViewController.viewModel = SearchTimelineViewModel(context: context)
        
        searchMediaViewController.context = context
        searchMediaViewController.coordinator = coordinator
        searchMediaViewController.viewModel = SearchMediaViewModel(context: context)
        
        searchUserViewController.context = context
        searchUserViewController.coordinator = coordinator
        searchUserViewController.viewModel = SearchUserViewModel(context: context)
        
        searchText
            .assign(to: \.value, on: searchTimelineViewController.viewModel.searchText)
            .store(in: &disposeBag)
        searchText
            .assign(to: \.value, on: searchMediaViewController.viewModel.searchText)
            .store(in: &disposeBag)
        searchText
            .assign(to: \.value, on: searchUserViewController.viewModel.searchText)
            .store(in: &disposeBag)
        
        searchActionPublisher
            .subscribe(searchTimelineViewController.viewModel.searchActionPublisher)
            .store(in: &disposeBag)
        searchActionPublisher
            .subscribe(searchMediaViewController.viewModel.searchActionPublisher)
            .store(in: &disposeBag)
        searchActionPublisher
            .subscribe(searchUserViewController.viewModel.searchActionPublisher)
            .store(in: &disposeBag)
    }
}

// MARK: - PageboyViewControllerDataSource
extension SearchDetailPagingViewModel: PageboyViewControllerDataSource {
    
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
extension SearchDetailPagingViewModel: TMBarDataSource {
    
    func barItem(for bar: TMBar, at index: Int) -> TMBarItemable {
        return barItems[index]
    }
    
}

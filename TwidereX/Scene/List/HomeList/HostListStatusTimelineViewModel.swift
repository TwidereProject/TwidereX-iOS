//
//  HostListStatusTimelineViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2023/4/26.
//  Copyright © 2023 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreDataStack

protocol HomeListStatusTimelineViewModelDelegate: AnyObject {
    func homeListStatusTimelineViewModel(_ viewModel: HomeListStatusTimelineViewModel, menuActionDidSelect menuActionViewModel: HomeListStatusTimelineViewModel.HomeListMenuActionViewModel)
}

final class HomeListStatusTimelineViewModel: ObservableObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    let authContext: AuthContext
    
    let viewDidAppear = CurrentValueSubject<Void, Never>(Void())
    
    let ownedListViewModel: ListViewModel
    let subscribedListViewModel: ListViewModel
    
    weak var delegate: HomeListStatusTimelineViewModelDelegate?
    
    // output
    @Published var ownedListMenuActionViewModels: [HomeListMenuActionViewModel] = []
    @Published var subscribedListMenuActionViewModels: [HomeListMenuActionViewModel] = []
    @Published var homeListMenuContext: HomeListMenuContext?
    
    init(
        context: AppContext,
        authContext: AuthContext
    ) {
        self.context  = context
        self.authContext = authContext
        if let me = authContext.authenticationContext.user(in: context.managedObjectContext)?.asRecord {
            self.ownedListViewModel = ListViewModel(context: context, authContext: authContext, kind: .owned(user: me))
            self.subscribedListViewModel = ListViewModel(context: context, authContext: authContext, kind: .subscribed(user: me))
        } else {
            self.ownedListViewModel = ListViewModel(context: context, authContext: authContext, kind: .none)
            self.subscribedListViewModel = ListViewModel(context: context, authContext: authContext, kind: .none)
        }
        // end init
        
        Publishers.CombineLatest(
            $ownedListMenuActionViewModels,
            $subscribedListMenuActionViewModels
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _, _ in
            guard let self = self else { return }
            _ = self.createHomeListMenuContext()
        }
        .store(in: &disposeBag)
        
        ownedListViewModel.fetchedResultController.$records
            .receive(on: DispatchQueue.main)
            .compactMap { [weak self] records -> [HomeListMenuActionViewModel]? in
                guard let self = self else { return nil }
                return records
                    .compactMap { record in record.object(in: self.context.managedObjectContext) }
                    .map { object in HomeListMenuActionViewModel(list: object) }
            }
            .assign(to: &$ownedListMenuActionViewModels)
        subscribedListViewModel.fetchedResultController.$records
            .receive(on: DispatchQueue.main)
            .compactMap { [weak self] records -> [HomeListMenuActionViewModel]? in
                guard let self = self else { return nil }
                return records
                    .compactMap { record in record.object(in: self.context.managedObjectContext) }
                    .map { object in HomeListMenuActionViewModel(list: object) }
            }
            .assign(to: &$subscribedListMenuActionViewModels)
    }
    
}

extension HomeListStatusTimelineViewModel {
    class HomeListMenuActionViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        
        // input
        let list: ListObject
        
        // output
        @Published var title: String = ""
        @Published var activeAt: Date? = nil
        
        init(list: ListObject) {
            self.list = list
            // end init
            
            setup(list: list)
        }
    }
    
    struct HomeListMenuContext {
        let ownedListMenu: UIMenu
        let subscribedListMenu: UIMenu
        let isEmpty: Bool
        let activeMenuActionViewModel: HomeListMenuActionViewModel?
    }
}

extension HomeListStatusTimelineViewModel {
    @discardableResult
    func createHomeListMenuContext() -> HomeListMenuContext {
        let ownedListMenuActionViewModels = self.ownedListMenuActionViewModels
        let subscribedListMenuActionViewModels = self.subscribedListMenuActionViewModels
        
        
        let latestActiveViewModel: HomeListMenuActionViewModel? = {
            var menuActionViewModels: [HomeListMenuActionViewModel] = []
            menuActionViewModels.append(contentsOf: ownedListMenuActionViewModels)
            menuActionViewModels.append(contentsOf: subscribedListMenuActionViewModels)
            
            var latestActiveViewModel = menuActionViewModels.first
            for menuActionViewModel in menuActionViewModels {
                guard let activeAt = menuActionViewModel.activeAt else { continue }
                if let latestActiveAt = latestActiveViewModel?.activeAt {
                    if activeAt > latestActiveAt {
                        latestActiveViewModel = menuActionViewModel
                    } else {
                        continue
                    }
                } else {
                    latestActiveViewModel = menuActionViewModel
                }
            }
            return latestActiveViewModel
        }()
        
        // owned lists
        let ownedListMenuActions: [UIMenuElement] = ownedListMenuActionViewModels.map { viewModel in
            let state: UIMenuElement.State = viewModel === latestActiveViewModel ? .on : .off
            return UIAction(title: viewModel.title, state: state) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.homeListStatusTimelineViewModel(self, menuActionDidSelect: viewModel)
            }
        }
        let ownedListMenu = UIMenu(title: "Lists", options: .displayInline, children: ownedListMenuActions)
        // subscribed lists
        let subscribedListMenuActions: [UIMenuElement] = subscribedListMenuActionViewModels.map { viewModel in
            let state: UIMenuElement.State = viewModel === latestActiveViewModel ? .on : .off
            return UIAction(title: viewModel.title, state: state) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.homeListStatusTimelineViewModel(self, menuActionDidSelect: viewModel)
            }
        }
        let subscribedListMenu = UIMenu(title: "Subscribed", options: .displayInline, children: subscribedListMenuActions)
        
        let isEmpty: Bool = {
            guard ownedListMenuActions.isEmpty else { return false }
            guard subscribedListMenuActions.isEmpty else { return false }
            return true
        }()
        
        
        let homeListMenuContext = HomeListMenuContext(
            ownedListMenu: ownedListMenu,
            subscribedListMenu: subscribedListMenu,
            isEmpty: isEmpty,
            activeMenuActionViewModel: latestActiveViewModel
        )
        self.homeListMenuContext = homeListMenuContext
        
        return homeListMenuContext
    }   // end func
}

extension HomeListStatusTimelineViewModel.HomeListMenuActionViewModel {
    func setup(list: ListObject) {
        switch list {
        case .twitter(let object):
            setup(list: object)
        case .mastodon(let object):
            setup(list: object)
        }
    }
    
    func setup(list: TwitterList) {
        list.publisher(for: \.name)
            .assign(to: \.title, on: self)
            .store(in: &disposeBag)
        list.publisher(for: \.activeAt)
            .assign(to: \.activeAt, on: self)
            .store(in: &disposeBag)
    }
    
    func setup(list: MastodonList) {
        list.publisher(for: \.title)
            .assign(to: \.title, on: self)
            .store(in: &disposeBag)
        list.publisher(for: \.activeAt)
            .assign(to: \.activeAt, on: self)
            .store(in: &disposeBag)
    }
}
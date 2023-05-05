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
    @Published var homeTimelineMenuActionViewModels: [HomeListMenuActionViewModel]
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
        self.homeTimelineMenuActionViewModels = {
            guard let authenticationIndex = authContext.authenticationContext.authenticationIndex(in: context.managedObjectContext) else { return [] }
            return [HomeListMenuActionViewModel(timeline: .home(authenticationIndex))]
        }()
        // end init
        
        Publishers.CombineLatest(
            $ownedListMenuActionViewModels,
            $subscribedListMenuActionViewModels
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _, _ in
            guard let self = self else { return }
            Task { @MainActor in
                _ = self.createHomeListMenuContext()
            }   // end Task
        }
        .store(in: &disposeBag)
        
        ownedListViewModel.fetchedResultController.$records
            .receive(on: DispatchQueue.main)
            .compactMap { [weak self] records -> [HomeListMenuActionViewModel]? in
                guard let self = self else { return nil }
                return records
                    .compactMap { record in record.object(in: self.context.managedObjectContext) }
                    .map { object in HomeListMenuActionViewModel(timeline: .list(object)) }
            }
            .assign(to: &$ownedListMenuActionViewModels)
        subscribedListViewModel.fetchedResultController.$records
            .receive(on: DispatchQueue.main)
            .compactMap { [weak self] records -> [HomeListMenuActionViewModel]? in
                guard let self = self else { return nil }
                return records
                    .compactMap { record in record.object(in: self.context.managedObjectContext) }
                    .map { object in HomeListMenuActionViewModel(timeline: .list(object)) }
            }
            .assign(to: &$subscribedListMenuActionViewModels)
    }
    
}

extension HomeListStatusTimelineViewModel {
    class HomeListMenuActionViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        
        // input
        let timeline: Timeline
        
        // output
        @Published var title: String = ""
        @Published var activeAt: Date? = nil
        
        init(timeline: Timeline) {
            self.timeline = timeline
            // end init
            
            setup(timeline: timeline)
        }
        
        enum Timeline {
            case home(AuthenticationIndex)
            case list(ListObject)
        }
    }
}

extension HomeListStatusTimelineViewModel.HomeListMenuActionViewModel {
    func setup(timeline: Timeline) {
        switch timeline {
        case .home(let authenticationIndex):
            title = L10n.Scene.Timeline.title
            authenticationIndex.publisher(for: \.homeTimelineActiveAt)
                .assign(to: \.activeAt, on: self)
                .store(in: &disposeBag)
        case .list(let list):
            switch list {
            case .twitter(let object):
                setup(list: object)
            case .mastodon(let object):
                setup(list: object)
            }
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

extension HomeListStatusTimelineViewModel {
    struct HomeListMenuContext {
        let homeTimelineMenu: UIMenu
        let ownedListMenu: UIMenu
        let subscribedListMenu: UIMenu
        let isEmpty: Bool
        let activeMenuActionViewModel: HomeListMenuActionViewModel?
    }
}

extension HomeListStatusTimelineViewModel {
    @MainActor
    @discardableResult
    func createHomeListMenuContext() -> HomeListMenuContext {
        let homeTimelineMenuActionViewModels = self.homeTimelineMenuActionViewModels
        let ownedListMenuActionViewModels = self.ownedListMenuActionViewModels
        let subscribedListMenuActionViewModels = self.subscribedListMenuActionViewModels
        
        let latestActiveViewModel: HomeListMenuActionViewModel? = {
            var menuActionViewModels: [HomeListMenuActionViewModel] = []
            menuActionViewModels.append(contentsOf: homeTimelineMenuActionViewModels)
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
        
        // home timeline
        let homeTimelineMenuActions: [UIMenuElement] = homeTimelineMenuActionViewModels.map { viewModel in
            let state: UIMenuElement.State = viewModel === latestActiveViewModel ? .on : .off
            return UIAction(title: viewModel.title, state: state) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.homeListStatusTimelineViewModel(self, menuActionDidSelect: viewModel)
            }
        }
        let homeTimelineMenu = UIMenu(title: "", options: .displayInline, children: homeTimelineMenuActions)
        
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
            homeTimelineMenu: homeTimelineMenu,
            ownedListMenu: ownedListMenu,
            subscribedListMenu: subscribedListMenu,
            isEmpty: isEmpty,
            activeMenuActionViewModel: latestActiveViewModel
        )
        self.homeListMenuContext = homeListMenuContext
        
        return homeListMenuContext
    }   // end func
}


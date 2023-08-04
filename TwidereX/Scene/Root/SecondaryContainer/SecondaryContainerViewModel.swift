//
//  SecondaryContainerViewModel.swift
//  TwidereX
//
//  Created by MainasuK on 2023/5/22.
//  Copyright © 2023 Twidere. All rights reserved.
//

import UIKit
import TwidereCommon

class SecondaryContainerViewModel: ObservableObject {
    
    // input
    let context: AppContext
    let auth: AuthContext
    
    @Published private(set) var width: CGFloat = 375
    
    // output
    @Published private var viewControllers: [UINavigationController] = []
    
    init(
        context: AppContext,
        auth: AuthContext
    ) {
        self.context = context
        self.auth = auth
        // end init
    }
    
}

extension SecondaryContainerViewModel {
    func addColumn(
        in stack: UIStackView,
        at index: Int? = nil,
        tab: TabBarItem?,
        viewController: UIViewController,
        setupColumnMenu: Bool = true,
        newColumnViewModel: NewColumnViewModel? = nil
    ) {
        let navigationController = UINavigationController(rootViewController: viewController)
        viewControllers.append(navigationController)
        
        let count = stack.arrangedSubviews.count
        if count == 0 {
            stack.addArrangedSubview(navigationController.view)
        } else {
            let at = min(count - 1, index ?? count - 1)
            stack.insertArrangedSubview(navigationController.view, at: at)
        }
        
        navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navigationController.view.widthAnchor.constraint(equalToConstant: width).identifier("width"),
            navigationController.view.heightAnchor.constraint(equalTo: stack.heightAnchor),
        ])
        
        if setupColumnMenu {
            setupColumnMenuBarButtonItem(
                in: stack,
                tab: tab,
                viewController: viewController,
                navigationController: navigationController,
                newColumnViewModel: newColumnViewModel
            )
        }
    }
    
    func update(width: CGFloat) {
        for viewController in viewControllers {
            guard let constraint = viewController.view.constraints.first(where: { $0.identifier == "width" }) else {
                continue
            }
            constraint.constant = width
        }
        
        self.width = width
    }
    
    func removeColumn(
        in stack: UIStackView,
        navigationController: UINavigationController
    ) -> Int? {
        let _index: Int? = stack.arrangedSubviews.firstIndex(where: { view in
            navigationController.view === view
        })
        guard let index = _index else { return nil }
        
        stack.removeArrangedSubview(navigationController.view)
        navigationController.view.removeFromSuperview()
        navigationController.view.isHidden = true
        self.viewControllers.removeAll(where: { $0 === navigationController })
        
        return index
    }
}

extension SecondaryContainerViewModel {
    private func setupColumnMenuBarButtonItem(
        in stack: UIStackView,
        tab: TabBarItem?,
        viewController: UIViewController,
        navigationController: UINavigationController,
        newColumnViewModel: NewColumnViewModel? = nil
    ) {
        let barButtonItem = UIBarButtonItem()
        barButtonItem.image = UIImage(systemName: "slider.horizontal.3")
        let deferredMenuElement = UIDeferredMenuElement.uncached { [weak self, weak stack, weak viewController, weak navigationController] handler in
            guard let self = self,
                  let stack = stack,
                  let viewController = viewController,
                  let navigationController = navigationController
            else {
                handler([])
                return
            }
                        
            var menuElements: [UIMenuElement] = []
            
            let closeColumnAction = UIAction(title: L10n.Scene.Column.Actions.closeColumn, image: UIImage(systemName: "xmark.square"), attributes: .destructive) { [weak self, weak stack, weak navigationController] _ in
                guard let self = self else { return }
                guard let stack = stack else { return }
                guard let navigationController = navigationController else { return }
                stack.removeArrangedSubview(navigationController.view)
                navigationController.view.removeFromSuperview()
                navigationController.view.isHidden = true
                self.viewControllers.removeAll(where: { $0 === navigationController })
            }
            menuElements.append(closeColumnAction)
            
            let _index: Int? = stack.arrangedSubviews.firstIndex(where: { view in
                return navigationController.view === view
            })
            if let index = _index {
                if index > 0 {
                    let moveLeftMenuAction = UIAction(title: L10n.Scene.Column.Actions.moveLeft, image: UIImage(systemName: "arrow.left.square")) { [weak self, weak stack, weak navigationController] _ in
                        guard let self = self else { return }
                        guard let stack = stack else { return }
                        guard let navigationController = navigationController else { return }
                        stack.removeArrangedSubview(navigationController.view)
                        stack.insertArrangedSubview(navigationController.view, at: index - 1)
                    }
                    menuElements.append(moveLeftMenuAction)
                }
                if index < stack.arrangedSubviews.count - 2 {
                    let moveRightMenuAction = UIAction(title: L10n.Scene.Column.Actions.moveRight, image: UIImage(systemName: "arrow.right.square")) { [weak self, weak stack, weak navigationController] _ in
                        guard let self = self else { return }
                        guard let stack = stack else { return }
                        guard let navigationController = navigationController else { return }
                        stack.removeArrangedSubview(navigationController.view)
                        stack.insertArrangedSubview(navigationController.view, at: index + 1)
                    }
                    menuElements.append(moveRightMenuAction)
                }
            }
            
            let menu = UIMenu(
                title: "",
                options: .displayInline,
                preferredElementSize: menuElements.count > 1 ? .small : .large,
                children: menuElements
            )
            handler([menu])
        }
        
        var children: [UIMenuElement] = [deferredMenuElement]
        
        if let newColumnViewModel = newColumnViewModel, let tab = tab {
            var tabs = newColumnViewModel.tabs
            tabs.removeAll(where: { $0 == tab })
            if !tabs.isEmpty {
                let openTabsMenu: UIMenu = NewColumnView.menu(
                    tabs: tabs,
                    viewModel: newColumnViewModel,
                    source: navigationController
                )
                children.append(openTabsMenu)
            }
        }
        
        barButtonItem.menu = UIMenu(title: "", options: .displayInline, children: children)
        viewController.navigationItem.leftBarButtonItem = barButtonItem
    }
}

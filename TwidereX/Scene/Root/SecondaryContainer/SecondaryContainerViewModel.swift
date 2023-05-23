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
        viewController: UIViewController,
        setupColumnMenu: Bool = true
    ) {
        let navigationController = UINavigationController(rootViewController: viewController)
        viewControllers.append(navigationController)
        
        let count = stack.arrangedSubviews.count
        if count == 0 {
            stack.addArrangedSubview(navigationController.view)
        } else {
            stack.insertArrangedSubview(navigationController.view, at: count - 1)
        }
        
        navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navigationController.view.widthAnchor.constraint(equalToConstant: width).identifier("width"),
            navigationController.view.heightAnchor.constraint(equalTo: stack.heightAnchor),
        ])
        
        if setupColumnMenu {
            setupColumnMenuBarButtonItem(
                in: stack,
                viewController: viewController,
                navigationController: navigationController
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
}

extension SecondaryContainerViewModel {
    private func setupColumnMenuBarButtonItem(
        in stack: UIStackView,
        viewController: UIViewController,
        navigationController: UINavigationController
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
            
            let closeColumnAction = UIAction(title: "Close column", image: UIImage(systemName: "xmark.square")) { [weak self, weak stack, weak navigationController] _ in
                guard let self = self else { return }
                guard let stack = stack else { return }
                guard let navigationController = navigationController else { return }
                stack.removeArrangedSubview(navigationController.view)
                navigationController.view.removeFromSuperview()
                navigationController.view.isHidden = true
                self.viewControllers.removeAll(where: { $0 === navigationController })
            }
            let closeMenu = UIMenu(title: "", options: .displayInline, children: [closeColumnAction])
            menuElements.append(closeMenu)
            
            let _index: Int? = stack.arrangedSubviews.firstIndex(where: { view in
                return navigationController.view === view
            })
            if let index = _index {
                var moveMenuElements: [UIMenuElement] = []
                if index > 0 {
                    let moveLeftMenuAction = UIAction(title: "Move left", image: UIImage(systemName: "arrow.left.square")) { [weak self, weak stack, weak navigationController] _ in
                        guard let self = self else { return }
                        guard let stack = stack else { return }
                        guard let navigationController = navigationController else { return }
                        stack.removeArrangedSubview(navigationController.view)
                        stack.insertArrangedSubview(navigationController.view, at: index - 1)
                    }
                    moveMenuElements.append(moveLeftMenuAction)
                }
                if index < stack.arrangedSubviews.count - 2 {
                    let moveRightMenuAction = UIAction(title: "Move Right", image: UIImage(systemName: "arrow.right.square")) { [weak self, weak stack, weak navigationController] _ in
                        guard let self = self else { return }
                        guard let stack = stack else { return }
                        guard let navigationController = navigationController else { return }
                        stack.removeArrangedSubview(navigationController.view)
                        stack.insertArrangedSubview(navigationController.view, at: index + 1)
                    }
                    moveMenuElements.append(moveRightMenuAction)
                }
                if !moveMenuElements.isEmpty {
                    let moveMenu = UIMenu(title: "", options: .displayInline, children: moveMenuElements)
                    menuElements.append(moveMenu)
                }
            }
            
            let menu = UIMenu(title: "", options: .displayInline, children: menuElements)
            handler([menu])
        }
        barButtonItem.menu = UIMenu(title: "", options: .displayInline, children: [deferredMenuElement])
        viewController.navigationItem.leftBarButtonItem = barButtonItem
    }
}

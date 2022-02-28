//
//  NeedsDependency+AvatarBarButtonItemDelegate.swift
//  TwidereX
//
//  Created by MainasuK on 2022-2-21.
//  Copyright © 2022 Twidere. All rights reserved.
//

import UIKit

// MARK: - AvatarBarButtonItemDelegate
extension NeedsDependency where Self: AvatarBarButtonItemDelegate {
    
    func avatarBarButtonItem(
        _ barButtonItem: AvatarBarButtonItem,
        didLongPressed sender: UILongPressGestureRecognizer
    ) {
        Task { @MainActor in
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            feedbackGenerator.impactOccurred()
            
            let accountListViewModel = AccountListViewModel(context: context)
            coordinator.present(
                scene: .accountList(viewModel: accountListViewModel),
                from: nil,
                transition: .modal(animated: true, completion: nil)
            )
        }   // end Task
    }

}

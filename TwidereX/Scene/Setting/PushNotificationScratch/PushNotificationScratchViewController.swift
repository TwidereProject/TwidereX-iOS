//
//  PushNotificationScratchViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-18.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import SwiftUI
import TwidereCore

final class PushNotificationScratchViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    private(set) lazy var viewModel = PushNotificationScratchViewModel(context: context)
    private(set) lazy var accountPreferenceView = PushNotificationScratchView(viewModel: viewModel)

}

extension PushNotificationScratchViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Push Notification Scratch"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(PushNotificationScratchViewController.cancelBarButtonItemDidPressed(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Show", style: .plain, target: self, action: #selector(PushNotificationScratchViewController.showBarButtonItemDidPressed(_:)))
        
        let hostingController = UIHostingController(rootView: accountPreferenceView)
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostingController.didMove(toParent: self)
    }
    
}

extension PushNotificationScratchViewController {
    
    @objc private func cancelBarButtonItemDidPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    @objc private func showBarButtonItemDidPressed(_ sender: UIBarButtonItem) {
        Task {
            // accessToken
            guard let account = viewModel.accounts[safe: viewModel.activeAccountIndex],
                  let authenticationContext = account.authenticationContext
            else {
                return
            }
            
            let _accessToken: String? = {
                switch authenticationContext {
                case .twitter:
                    return nil
                case .mastodon(let authenticationContext):
                    return authenticationContext.authorization.accessToken
                }
            }()
            guard let accessToken = _accessToken else {
                return
            }
            
            // notification ID
            let notificationID: String = {
                if viewModel.isRandomNotification {
                    return account.notifications.randomElement()?.id ?? ""
                } else {
                    return viewModel.notificationID
                }
            }()
            
            let pushNotification = MastodonPushNotification(
                accessToken: accessToken,
                notificationID: Int(notificationID) ?? -1,
                notificationType: "",
                preferredLocale: nil,
                icon: nil,
                title: "",
                body: ""
            )
            
            self.dismiss(animated: true) {
                Task {
                    await self.context.notificationService.revealNotificationAction.send(pushNotification)
                }   // end Task
            }
        }   // end Task
    }
    
}



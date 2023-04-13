//
//  NotificationView+ViewModel.swift
//  
//
//  Created by MainasuK on 2023/4/11.
//

import os.log
import SwiftUI
import Combine
import CoreDataStack

extension NotificationView {
    public class ViewModel: ObservableObject {
        
        let logger = Logger(subsystem: "StatusView", category: "ViewModel")

        @Published public var viewLayoutFrame = ViewLayoutFrame()
        
        
        // input
        public let notification: NotificationObject
        public let authContext: AuthContext?

        // output
        
        // user
        @Published public var userViewModel: UserView.ViewModel?
        
        // status
        @Published public var statusViewModel: StatusView.ViewModel?
        
        // header
        @Published var notificationHeaderViewModel: StatusHeaderView.ViewModel?
        
        public init(
            notification: NotificationObject,
            authContext: AuthContext?,
            viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?,
            statusViewModel: StatusView.ViewModel?,
            userViewModel: UserView.ViewModel?
        ) {
            self.notification = notification
            self.authContext = authContext
            self.statusViewModel = statusViewModel
            self.userViewModel = userViewModel
            // end init
            
            viewLayoutFramePublisher?.assign(to: &$viewLayoutFrame)
        }

    }
}

extension NotificationView.ViewModel {
    public convenience init(
        notification: NotificationObject,
        authContext: AuthContext?,
        statusViewDelegate: StatusViewDelegate?,
        userViewDelegate: UserViewDelegate?,
        viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
    ) {
        switch notification {
        case .twitter(let status):
            self.init(
                notification: notification,
                authContext: authContext,
                viewLayoutFramePublisher: viewLayoutFramePublisher,
                statusViewModel: .init(
                    status: status,
                    authContext: authContext,
                    kind: .timeline,
                    delegate: statusViewDelegate,
                    parentViewModel: nil,
                    viewLayoutFramePublisher: viewLayoutFramePublisher
                ),
                userViewModel: nil
            )
        case .mastodon(let notification):
            self.init(
                notification: notification,
                authContext: authContext,
                statusViewDelegate: statusViewDelegate,
                userViewDelegate: userViewDelegate,
                viewLayoutFramePublisher: viewLayoutFramePublisher
            )
        }
    }   // end init
}

extension NotificationView.ViewModel {
    public convenience init(
        notification: MastodonNotification,
        authContext: AuthContext?,
        statusViewDelegate: StatusViewDelegate?,
        userViewDelegate: UserViewDelegate?,
        viewLayoutFramePublisher: Published<ViewLayoutFrame>.Publisher?
    ) {
        self.init(
            notification: .mastodon(object: notification),
            authContext: authContext,
            viewLayoutFramePublisher: viewLayoutFramePublisher,
            statusViewModel: {
                guard let status = notification.status else { return nil }
                return StatusView.ViewModel(
                    status: status,
                    authContext: authContext,
                    kind: .timeline,
                    delegate: statusViewDelegate,
                    parentViewModel: nil,
                    viewLayoutFramePublisher: viewLayoutFramePublisher
                )
            }(),
            userViewModel: {
                guard notification.status == nil else { return nil }
                let ViewModel = UserView.ViewModel(
                    user: notification.account,
                    authContext: authContext,
                    kind: .notification(.mastodon(object: notification)),
                    delegate: userViewDelegate
                )
                return ViewModel
            }()
        )
        
        // header
        let _info = NotificationHeaderInfo(
            type: notification.notificationType,
            user: notification.account
        )
        if let info = _info {
            let _notificationHeaderViewModel = StatusHeaderView.ViewModel(
                image: info.iconImage,
                label: info.textMetaContent
            )
            _notificationHeaderViewModel.hasHangingAvatar = true
            self.notificationHeaderViewModel = _notificationHeaderViewModel
        }
    }   // end init
}

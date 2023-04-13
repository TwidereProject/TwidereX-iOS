//
//  NotificationView.swift
//  
//
//  Created by MainasuK on 2023/4/11.
//

import SwiftUI

public struct NotificationView: View {
    
    static var verticalMargin: CGFloat = 8
    
    @ObservedObject public private(set) var viewModel: ViewModel
    
     @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    public init(viewModel: NotificationView.ViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: .zero) {
            // header
            if let notificationHeaderViewModel = viewModel.notificationHeaderViewModel {
                StatusHeaderView(viewModel: notificationHeaderViewModel)
                    .padding(.top, NotificationView.verticalMargin)
                    .allowsHitTesting(false)
            }
            // status
            if let statusViewModel = viewModel.statusViewModel {
                StatusView(viewModel: statusViewModel)
            } else {
                if let userViewModel = viewModel.userViewModel {
                    UserView(viewModel: userViewModel)
                }
                Color.clear
                    .frame(height: NotificationView.verticalMargin)
                    .overlay {
                        HStack(spacing: StatusView.hangingAvatarButtonTrailingSpacing) {
                            Color.clear.frame(width: StatusView.hangingAvatarButtonDimension)
                            VStack(spacing: .zero) {
                                Spacer()
                                Divider()
                                Color.clear.frame(height: 1)
                            }
                        }
                    }   // end overlay
            }   // end if … else
        }
    }

}

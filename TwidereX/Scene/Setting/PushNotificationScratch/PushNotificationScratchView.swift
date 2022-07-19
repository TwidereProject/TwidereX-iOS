//
//  PushNotificationScratchView.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-18.
//  Copyright © 2022 Twidere. All rights reserved.
//

import Foundation
import SwiftUI

struct PushNotificationScratchView: View {
    
    @ObservedObject var viewModel: PushNotificationScratchViewModel
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $viewModel.isRandomNotification) {
                    Text("Random Notification")
                }
                if !viewModel.isRandomNotification {
                    TextField("Notification ID", text: $viewModel.notificationID)
                }
            }
            Section {
                Picker("Account:", selection: $viewModel.activeAccountIndex) {
                    ForEach(Array(viewModel.accounts.enumerated()), id: \.0) { index, account in
                        let username = "@" + account.username
                        Text(username)
                    }
                }
                .pickerStyle(.inline)
            }
        }   // end Form
    }   // end body
    
}

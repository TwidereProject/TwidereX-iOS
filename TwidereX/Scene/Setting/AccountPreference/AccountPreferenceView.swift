//
//  AccountPreferenceView.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-12.
//  Copyright © 2022 Twidere. All rights reserved.
//

import Foundation
import SwiftUI
import TwidereUI

enum AccountPreferenceListEntry: Hashable {
    case muted
    case blocked
    case accountSettings
    case signout
    
    var title: String {
        switch self {
        case .muted:                return L10n.Scene.Settings.Account.mutedPeople
        case .blocked:              return L10n.Scene.Settings.Account.blockedPeople
        case .accountSettings:      return L10n.Scene.Settings.Account.accountSettings
        case .signout:              return L10n.Common.Controls.Actions.signOut
        }
    }
}

struct AccountPreferenceView: View {
    
    @ObservedObject var viewModel: AccountPreferenceViewModel
    
    @State var isPushNotificationEnabled = true
    
    var muteAndBlockSection: some View {
        Section(header: Text(L10n.Scene.Settings.Account.muteAndBlock)) {
            let entries: [AccountPreferenceListEntry] = [
                .muted, .blocked
            ]
            ForEach(entries, id: \.self) { entry in
                Button {
                    viewModel.listEntryPublisher.send(entry)
                } label: {
                    TableViewEntryRow(icon: nil, title: entry.title)
                        .foregroundColor(Color(.label))
                }
            }
        }
    }

    
    var body: some View {
        List {
            // user header section
            Section {
                UserContentView(viewModel: .init(
                    user: viewModel.user,
                    accessoryType: .none
                ))
            }
            // notification section
            if let viewModel = viewModel.mastodonNotificationSectionViewModel {
                MastodonNotificationSectionView(viewModel: viewModel)
            }
            // mute & block section
            // muteAndBlockSection
            // account settings secton
            // Section {
            //     let entry = AccountPreferenceListEntry.accountSettings
            //     Button {
            //         viewModel.listEntryPublisher.send(entry)
            //     } label: {
            //         TableViewEntryRow(icon: nil, title: entry.title, accessorySymbolName: "arrow.up.right.square")
            //             .foregroundColor(Color(.label))
            //     }
            // }
            // sign out section
            Section {
                let entry = AccountPreferenceListEntry.signout
                Button {
                    viewModel.listEntryPublisher.send(entry)
                } label: {
                    TableViewEntryRow(icon: nil, title: entry.title, accessorySymbolName: nil)
                        .foregroundColor(Color(uiColor: .systemRed))
                }
            }
        }   // end List
    }
    
}

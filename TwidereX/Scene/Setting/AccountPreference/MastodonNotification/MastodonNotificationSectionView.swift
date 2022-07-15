//
//  MastodonNotificationSectionView.swift
//  TwidereX
//
//  Created by MainasuK on 2022-7-14.
//  Copyright © 2022 Twidere. All rights reserved.
//

import Foundation
import SwiftUI
import CoreDataStack
import SwiftMessages

struct MastodonNotificationSectionView: View {
    
    @ObservedObject var viewModel: MastodonNotificationSectionViewModel
    
    var body: some View {
        Group {
            // push notification secion
            Section {
                Toggle("Push Notification", isOn: Binding(
                    get: { viewModel.isActive },
                    set: { newValue in
                        viewModel.isActive = newValue
                        viewModel.updateNotificationSubscription { notificationSubscription in
                            notificationSubscription.update(isActive: newValue)
                        }
                    }
                ))
            }
            // notification option section
            if viewModel.isActive {
                notificationOptionSection
                #if DEBUG
                // // mention option section
                // if viewModel.isMentionEnabled {
                //     mentionPreferenceSection
                // }
                #endif
            }
        }   // end Group
    }   // end body
    
}

extension MastodonNotificationSectionView {
    
    var notificationOptionSection: some View {
        Section(header: Text("Notifications")) {
            Toggle("New Follow", isOn: Binding(
                get: { viewModel.isNewFollowEnabled },
                set: { newValue in
                    viewModel.isNewFollowEnabled = newValue
                    viewModel.updateNotificationSubscription { notificationSubscription in
                        notificationSubscription.update(follow: newValue)
                    }
                }
            ))
            Toggle("Reblog", isOn: Binding(
                get: { viewModel.isReblogEnabled },
                set: { newValue in
                    viewModel.isReblogEnabled = newValue
                    viewModel.updateNotificationSubscription { notificationSubscription in
                        notificationSubscription.update(reblog: newValue)
                    }
                }
            ))
            Toggle("Favorite", isOn: Binding(
                get: { viewModel.isFavoriteEnabled },
                set: { newValue in
                    viewModel.isFavoriteEnabled = newValue
                    viewModel.updateNotificationSubscription { notificationSubscription in
                        notificationSubscription.update(favourite: newValue)
                    }
                }
            ))
            Toggle("Poll", isOn: Binding(
                get: { viewModel.isPollEnabled },
                set: { newValue in
                    viewModel.isPollEnabled = newValue
                    viewModel.updateNotificationSubscription { notificationSubscription in
                        notificationSubscription.update(poll: newValue)
                    }
                }
            ))
            Toggle("Mention", isOn: Binding(
                get: { viewModel.isMentionEnabled },
                set: { newValue in
                    viewModel.isMentionEnabled = newValue
                    viewModel.updateNotificationSubscription { notificationSubscription in
                        notificationSubscription.update(mention: newValue)
                    }
                }
            ))
        }   // end Section
    }
    
    var mentionPreferenceSection: some View {
        Section(
            header: Text("Notifications: Mention"),
            footer:
                Group {
                    switch viewModel.mentionPreference {
                    case .everyone:
                        EmptyView()
                    case .follows:
                        Text("Only mentions from your following account will be received.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }   // end Group
        ) {
            Picker(selection: Binding(
                get: { viewModel.mentionPreference },
                set: { newValue in
                    viewModel.mentionPreference = newValue
                    viewModel.updateNotificationSubscription { notificationSubscription in
                        let mentionPreference = MastodonNotificationSubscription.MentionPreference(preference: newValue)
                        notificationSubscription.update(mentionPreference: mentionPreference)
                    }
                }
            )) {
                ForEach(MastodonNotificationSubscription.MentionPreference.Preference.allCases) { prefence in
                    Text(prefence.title)
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)
        }   // end Section
    }
    
}

extension MastodonNotificationSubscription.MentionPreference.Preference {
    fileprivate var title: String {
        switch self {
        case .everyone:     return "Everyone"
        case .follows:      return "Follows"
        }
    }
}

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
                Toggle(L10n.Scene.Settings.Notification.pushNotification, isOn: Binding(
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
        Section(header: Text(L10n.Scene.Settings.Notification.title)) {
            Toggle(L10n.Scene.Settings.Notification.Mastodon.newFollow, isOn: Binding(
                get: { viewModel.isNewFollowEnabled },
                set: { newValue in
                    viewModel.isNewFollowEnabled = newValue
                    viewModel.updateNotificationSubscription { notificationSubscription in
                        notificationSubscription.update(follow: newValue)
                    }
                }
            ))
            Toggle(L10n.Scene.Settings.Notification.Mastodon.reblog, isOn: Binding(
                get: { viewModel.isReblogEnabled },
                set: { newValue in
                    viewModel.isReblogEnabled = newValue
                    viewModel.updateNotificationSubscription { notificationSubscription in
                        notificationSubscription.update(reblog: newValue)
                    }
                }
            ))
            Toggle(L10n.Scene.Settings.Notification.Mastodon.favorite, isOn: Binding(
                get: { viewModel.isFavoriteEnabled },
                set: { newValue in
                    viewModel.isFavoriteEnabled = newValue
                    viewModel.updateNotificationSubscription { notificationSubscription in
                        notificationSubscription.update(favourite: newValue)
                    }
                }
            ))
            Toggle(L10n.Scene.Settings.Notification.Mastodon.poll, isOn: Binding(
                get: { viewModel.isPollEnabled },
                set: { newValue in
                    viewModel.isPollEnabled = newValue
                    viewModel.updateNotificationSubscription { notificationSubscription in
                        notificationSubscription.update(poll: newValue)
                    }
                }
            ))
            Toggle(L10n.Scene.Settings.Notification.Mastodon.mention, isOn: Binding(
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
            header: Text("Notifications: Mention"), // TODO: i18n
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
        case .everyone:     return "Everyone"   // TODO: i18n
        case .follows:      return "Follows"
        }
    }
}

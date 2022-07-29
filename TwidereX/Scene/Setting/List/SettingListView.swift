//
//  SettingListView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-10.
//  Copyright © 2020 Twidere. All rights reserved.
//

import CoreData
import CoreDataStack
import SwiftUI
import TwidereUI

struct TextCaseEraseStyle: ViewModifier {
    func body(content: Content) -> some View {
        Group {
            if #available(iOS 14, *) {
                AnyView(content.textCase(.none))
            } else {
                content
            }
        }
    }
}

enum SettingListEntryType: Hashable {
    case account
    case behaviors
    case display
    case layout
    case webBrowser
    case appIcon
    case about
    
    #if DEBUG
    case developer
    #endif
    
    var image: Image {
        switch self {
        case .account:          return Image(systemName: "person")
        case .behaviors:        return Image(uiImage: Asset.Arrows.arrowRampRight.image)
        case .display:          return Image(uiImage: Asset.TextFormatting.textHeaderRedaction.image)
        case .layout:           return Image(uiImage: Asset.sidebarLeft.image)
        case .webBrowser:       return Image(uiImage: Asset.window.image)
        case .appIcon:          return Image(uiImage: Asset.Logo.twidere.image)
        case .about:            return Image(uiImage: Asset.Indices.infoCircle.image)
        #if DEBUG
        case .developer:        return Image(systemName: "hammer")
        #endif
        }
    }
    
    var title: String {
        switch self {
        case .account:          return L10n.Scene.Settings.SectionHeader.account
        case .behaviors:        return "Behaviors"      // TODO: i18n
        case .display:          return L10n.Scene.Settings.Display.title
        case .layout:           return "Layout"
        case .webBrowser:       return "Web Browser"
        case .appIcon:          return L10n.Scene.Settings.Appearance.appIcon
        case .about:            return L10n.Scene.Settings.About.title
        #if DEBUG
        case .developer:        return "Developer"
        #endif
        }
    }
}

struct SettingListEntry: Identifiable {
    var id: SettingListEntryType { return type }
    let type: SettingListEntryType
    let image: Image
    let title: String
}

struct SettingListView: View {
    
    @EnvironmentObject var context: AppContext
    @ObservedObject var viewModel: SettingListViewModel
    
    static let accountListEntry: SettingListEntry = {
        let type = SettingListEntryType.account
        return SettingListEntry(type: type, image: type.image, title: type.title)
    }()
    
    @ViewBuilder
    var accountView: some View {
        if let user = viewModel.user {
            UserContentView(viewModel: .init(
                user: user,
                accessoryType: .disclosureIndicator
            ))
        } else {
            EmptyView()
        }
    }

    static let generalSection: [SettingListEntry] = {
        let types: [SettingListEntryType]  = [
            .behaviors,
            .display,
//            .layout,
//            .webBrowser
        ]
        return types.map { type in
            return SettingListEntry(type: type, image: type.image, title: type.title)
        }
    }()
    
    var appIconRow: some View {
        Button {
            
        } label: {
            HStack {
                Text(L10n.Scene.Settings.Appearance.appIcon)
                Spacer()
                Image(uiImage: UIImage(named: "\(viewModel.alternateIconNamePreference.iconName)") ?? UIImage())
                    .cornerRadius(4)
            }
        }
        .tint(Color(uiColor: .label))
    }
    
    static let aboutSection: [SettingListEntry] = {
        let types: [SettingListEntryType]  = [
            .about,
        ]
        return types.map { type in
            return SettingListEntry(type: type, image: type.image, title: type.title)
        }
    }()
    
    #if DEBUG
    static let developerSection: [SettingListEntry] = {
        let types: [SettingListEntryType]  = [
            .developer,
        ]
        return types.map { type in
            return SettingListEntry(type: type, image: type.image, title: type.title)
        }
    }()
    #endif
    
    var body: some View {
        List {
            // Account Section
            Section {
                Button {
                    viewModel.settingListEntryPublisher.send(SettingListView.accountListEntry)
                } label: {
                    accountView
                }
            } header: {
                Text(verbatim: L10n.Scene.Settings.SectionHeader.account)
                    .textCase(nil)
            }
            // General Section
            Section {
                ForEach(SettingListView.generalSection) { entry in
                    Button(action: {
                        viewModel.settingListEntryPublisher.send(entry)
                    }, label: {
                        TableViewEntryRow(icon: entry.image, title: entry.title)
                            .foregroundColor(Color(.label))
                    })
                }
            } header: {
                Text(verbatim: L10n.Scene.Settings.SectionHeader.general)
                    .textCase(nil)
            }
            // App Icon Section
            Section {
                NavigationLink {
                    AppIconPreferenceView()
                } label: {
                    appIconRow
                }
            }
            // About Section
            Section {
                ForEach(SettingListView.aboutSection) { entry in
                    Button(action: {
                        viewModel.settingListEntryPublisher.send(entry)
                    }, label: {
                        TableViewEntryRow(icon: entry.image, title: entry.title)
                            .foregroundColor(Color(.label))
                    })
                }
            } header: {
                Text(verbatim: L10n.Scene.Settings.SectionHeader.about)
                    .textCase(nil)
            }
            #if DEBUG
            Section {
                ForEach(SettingListView.developerSection) { entry in
                    Button(action: {
                        viewModel.settingListEntryPublisher.send(entry)
                    }, label: {
                        TableViewEntryRow(icon: entry.image, title: entry.title)
                            .foregroundColor(Color(.label))
                    })
                }
            }
            #endif
        }
        .listStyle(InsetGroupedListStyle())
    }
    
}

#if DEBUG

struct SettingListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingListView(viewModel: SettingListViewModel(
                context: .shared,
                auth: nil
            ))
            SettingListView(viewModel: SettingListViewModel(
                context: .shared,
                auth: nil
            ))
            .preferredColorScheme(.dark)
        }
    }
}

#endif


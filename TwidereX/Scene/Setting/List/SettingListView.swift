//
//  SettingListView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-10.
//  Copyright © 2020 Twidere. All rights reserved.
//

import SwiftUI

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
    case appearance
    case display
    case layout
    case webBrowser
    case about
    
    #if DEBUG
    case developer
    #endif
    
    var image: Image {
        switch self {
        case .appearance:       return Image(uiImage: Asset.ObjectTools.clothes.image)
        case .display:          return Image(uiImage: Asset.TextFormatting.textHeaderRedaction.image)
        case .layout:           return Image(uiImage: Asset.sidebarLeft.image)
        case .webBrowser:       return Image(uiImage: Asset.window.image)
        case .about:            return Image(uiImage: Asset.Indices.infoCircle.image)
        #if DEBUG
        case .developer:        return Image(systemName: "hammer")
        #endif
        }
    }
    
    var title: String {
        switch self {
        case .appearance:       return L10n.Scene.Settings.Appearance.title
        case .display:          return L10n.Scene.Settings.Display.title
        case .layout:           return "Layout"
        case .webBrowser:       return "Web Browser"
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
    
    static let generalSection: [SettingListEntry] = {
        let types: [SettingListEntryType]  = [
//            .appearance,
            .display,
//            .layout,
//            .webBrowser
        ]
        return types.map { type in
            return SettingListEntry(type: type, image: type.image, title: type.title)
        }
    }()
    
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
            Section(
                // grouped tableView get header padding since iOS 15.
                // no more top padding manually
                // seealso: 'UITableView.sectionHeaderTopPadding'
                header: Text(verbatim: L10n.Scene.Settings.SectionHeader.general)
            ) {
                ForEach(SettingListView.generalSection) { entry in
                    Button(action: {
                        context.viewStateStore.settingView.presentSettingListEntryPublisher.send(entry)
                    }, label: {
                        TableViewEntryRow(icon: entry.image, title: entry.title)
                            .foregroundColor(Color(.label))
                    })
                }
            }
            .modifier(TextCaseEraseStyle())
            Section(header: Text(verbatim: L10n.Scene.Settings.SectionHeader.about)) {
                ForEach(SettingListView.aboutSection) { entry in
                    Button(action: {
                        context.viewStateStore.settingView.presentSettingListEntryPublisher.send(entry)
                    }, label: {
                        TableViewEntryRow(icon: entry.image, title: entry.title)
                            .foregroundColor(Color(.label))
                    })
                }
            }
            .modifier(TextCaseEraseStyle())
            #if DEBUG
            Section {
                ForEach(SettingListView.developerSection) { entry in
                    Button(action: {
                        context.viewStateStore.settingView.presentSettingListEntryPublisher.send(entry)
                    }, label: {
                        TableViewEntryRow(icon: entry.image, title: entry.title)
                            .foregroundColor(Color(.label))
                    })
                }
            }
            .modifier(TextCaseEraseStyle())
            #endif
        }
        .listStyle(GroupedListStyle())
    }
    
}

#if DEBUG

struct SettingListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingListView()
            SettingListView()
                .preferredColorScheme(.dark)
        }
    }
}

#endif


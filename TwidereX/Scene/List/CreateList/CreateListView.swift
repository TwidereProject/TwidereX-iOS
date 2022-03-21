//
//  CreateListView.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-14.
//  Copyright © 2022 Twidere. All rights reserved.
//

import SwiftUI
import TwidereLocalization

struct CreateListView: View {
        
    @ObservedObject var viewModel: CreateListViewModel
    
    var body: some View {
        List {
            switch viewModel.platform {
            case .twitter:
                Section {
                    TextField(L10n.Scene.ListsModify.name, text: $viewModel.name)
                    TextField(L10n.Scene.ListsModify.description, text: $viewModel.description)
                    Toggle(L10n.Scene.ListsModify.private, isOn: $viewModel.isPrivate)
                }
            case .mastodon:
                Section {
                    TextField(L10n.Scene.ListsModify.name, text: $viewModel.name)
                }
            case .none:
                Spacer()
            }
        }
        .listStyle(GroupedListStyle())
    }
    
}

#if DEBUG

struct CreateListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CreateListView(viewModel: CreateListViewModel(context: .shared, platform: .twitter))
            CreateListView(viewModel: CreateListViewModel(context: .shared, platform: .twitter))
                .preferredColorScheme(.dark)
            CreateListView(viewModel: CreateListViewModel(context: .shared, platform: .mastodon))
            CreateListView(viewModel: CreateListViewModel(context: .shared, platform: .mastodon))
                .preferredColorScheme(.dark)
        }
    }
}

#endif


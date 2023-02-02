//
//  EditListView.swift
//  TwidereX
//
//  Created by MainasuK on 2022-3-14.
//  Copyright © 2022 Twidere. All rights reserved.
//

import SwiftUI
import TwidereLocalization

struct EditListView: View {
        
    @ObservedObject var viewModel: EditListViewModel
    
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
            if let authContext = AuthContext.mock(context: .shared) {
                EditListView(viewModel: EditListViewModel(context: .shared, authContext: authContext, platform: .twitter, kind: .create))
                EditListView(viewModel: EditListViewModel(context: .shared, authContext: authContext, platform: .twitter, kind: .create))
                    .preferredColorScheme(.dark)
                EditListView(viewModel: EditListViewModel(context: .shared, authContext: authContext, platform: .mastodon, kind: .create))
                EditListView(viewModel: EditListViewModel(context: .shared, authContext: authContext, platform: .mastodon, kind: .create))
                    .preferredColorScheme(.dark)
            }
        }
    }
}

#endif


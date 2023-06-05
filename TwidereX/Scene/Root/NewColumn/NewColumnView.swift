//
//  NewColumnView.swift
//  TwidereX
//
//  Created by MainasuK on 2023/5/23.
//  Copyright © 2023 Twidere. All rights reserved.
//

import UIKit
import SwiftUI

protocol NewColumnViewDelegate: AnyObject {
    func newColumnView(_ viewModel: NewColumnViewModel, tabBarItemDidPressed tab: TabBarItem)
    func newColumnView(_ viewModel: NewColumnViewModel, source: UINavigationController, openTabMenuAction tab: TabBarItem)
}

struct NewColumnView: View {
    @ObservedObject var viewModel: NewColumnViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.tabs, id: \.self) { tab in
                Button {
                    viewModel.delegate?.newColumnView(viewModel, tabBarItemDidPressed: tab)
                } label: {
                    HStack {
                        Image(uiImage: tab.image)
                        Text("\(tab.title)")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }   // end HStack
                    .font(.subheadline)
                    .foregroundColor(Color.primary)
                }
                .buttonStyle(.borderless)
            }   // end ForEach
        }   // end List
        .listStyle(.plain)
    }   // end body
}

extension NewColumnView {
    static func menu(
        tabs: [TabBarItem],
        viewModel: NewColumnViewModel,
        source: UINavigationController
    ) -> UIMenu {
        let actions: [UIAction] = tabs.map { tab in
            UIAction(title: tab.title, image: tab.image) { [weak viewModel, weak source] _ in
                guard let source = source,
                      let viewModel = viewModel
                else { return }
                viewModel.delegate?.newColumnView(viewModel, source: source, openTabMenuAction: tab)
            }
        }
        return UIMenu(options: .displayInline, children: actions)
    }
}

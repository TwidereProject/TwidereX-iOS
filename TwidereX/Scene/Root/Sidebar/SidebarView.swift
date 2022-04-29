//
//  SidebarView.swift
//  TwidereX
//
//  Created by MainasuK on 2022-4-28.
//  Copyright © 2022 Twidere. All rights reserved.
//

import SwiftUI
import TwidereAsset
import TwidereLocalization
import TwidereUI

struct SidebarView: View {
    
    @ObservedObject var viewModel: SidebarViewModel
    
    var body: some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.tabs, id: \.self) { item in
                let isActive: Bool = {
                    switch item {
                    case .tab(let tab):
                        return viewModel.activeTab == tab
                    default:
                        return false
                    }
                }()
                EntryButton(
                    item: item,
                    isActive: isActive
                ) { item in
                    viewModel.setActive(item: item)
                }
            }
            if !viewModel.entries.isEmpty {
                Divider()
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 1, alignment: .center)
                    .padding(.vertical, 15)
            }
            ForEach(viewModel.entries, id: \.self) { item in
                EntryButton(
                    item: item,
                    isActive: false
                ) { item in
                    viewModel.setActive(item: item)
                }
            }
            Spacer()
            EntryButton(
                item: .entry(.settings),
                isActive: false
            ) { item in
                viewModel.setActive(item: item)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
}

extension SidebarView {
    
    struct EntryButton: View {
        let item: SidebarViewModel.Item
        let isActive: Bool
        let action: (SidebarViewModel.Item) -> ()
        
        var body: some View {
            let dimension: CGFloat = 32
            let padding: CGFloat = 16
            Button {
                action(item)
            } label: {
                VectorImageView(
                    image: item.image,
                    tintColor: isActive ? .tintColor : .secondaryLabel
                )
                .frame(width: dimension, height: dimension, alignment: .center)
            }
            .frame(maxWidth: .infinity, maxHeight: dimension + 2 * padding, alignment: .center)
            .accessibilityLabel(item.title)
        }
    }
}

#if DEBUG
struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(viewModel: SidebarViewModel(context: .shared))
            .previewLayout(.fixed(width: 80, height: 800))
            
    }
}
#endif

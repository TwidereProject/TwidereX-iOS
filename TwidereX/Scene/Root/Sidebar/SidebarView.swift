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
            ForEach(viewModel.mainTabBarItems, id: \.self) { item in
                EntryButton(
                    item: item,
                    isActive: viewModel.activeTab == item
                ) { item in
                    viewModel.setActiveTab(item: item)
                }
            }
            if !viewModel.secondaryTabBarItems.isEmpty {
                Divider()
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 1, alignment: .center)
                    .padding(.top, 15 / 2)
            }
            ScrollView {
                Color.clear
                    .frame(height: 15 / 2, alignment: .center)
                ForEach(viewModel.secondaryTabBarItems, id: \.self) { item in
                    EntryButton(
                        item: item,
                        isActive: viewModel.activeTab == item
                    ) { item in
                        viewModel.setActiveTab(item: item)
                    }
                }
            }
            .introspectScrollView { scrollView in
                scrollView.alwaysBounceVertical = false
                scrollView.showsVerticalScrollIndicator = false
            }
            Spacer()
            EntryButton(
                item: .settings,
                isActive: false
            ) { item in
                viewModel.setActiveTab(item: item)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
}

extension SidebarView {
    
    struct EntryButton: View {
        let item: TabBarItem
        let isActive: Bool
        let action: (TabBarItem) -> ()
        
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
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: dimension + 2 * padding, alignment: .center)
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

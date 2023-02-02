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
import func QuartzCore.CACurrentMediaTime

struct SidebarView: View {
    
    @ObservedObject var viewModel: SidebarViewModel
    
    func shouldUseAltStyle(for item: TabBarItem) -> Bool {
        switch item {
        case .notification:
            return viewModel.hasUnreadPushNotification
        default:
            return false
        }
    }
    
    var body: some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.mainTabBarItems, id: \.self) { item in
                EntryButton(
                    item: item,
                    isActive: viewModel.activeTab == item,
                    useAltStyle: shouldUseAltStyle(for: item)
                ) { item in
                    viewModel.tap(item: item)
                } doubleTapAction: { item in
                    viewModel.doubleTap(item: item)
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
                        isActive: viewModel.activeTab == item,
                        useAltStyle: shouldUseAltStyle(for: item)
                    ) { item in
                        viewModel.tap(item: item)
                    } doubleTapAction: { item in
                        viewModel.doubleTap(item: item)
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
                isActive: false,
                useAltStyle: false
            ) { item in
                viewModel.tap(item: item)
            } doubleTapAction: { item in
                viewModel.doubleTap(item: item)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
}

extension SidebarView {
    
    struct EntryButton: View {
        
        @State var lastDoubleTapTime = CACurrentMediaTime()
        
        let item: TabBarItem
        let isActive: Bool
        let useAltStyle: Bool
        let tapAction: (TabBarItem) -> ()
        let doubleTapAction: (TabBarItem) -> ()
        
        var body: some View {
            let dimension: CGFloat = 32
            let padding: CGFloat = 16
            Button {
                // do nothing
            } label: {
                VectorImageView(
                    image: useAltStyle ? item.altImage : item.image,
                    tintColor: isActive ? .tintColor : .secondaryLabel
                )
                .frame(width: dimension, height: dimension, alignment: .center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(height: dimension + 2 * padding, alignment: .center)
            .accessibilityLabel(item.title)
            .simultaneousGesture(TapGesture().onEnded {
                let now = CACurrentMediaTime()
                guard now - lastDoubleTapTime > 0.1 else {
                    return
                }
                tapAction(item)
            })
            .simultaneousGesture(TapGesture(count: 2).onEnded {
                doubleTapAction(item)
                lastDoubleTapTime = CACurrentMediaTime()
            })
            // note:
            //  SwiftUI gesture `exclusive(before:)` not works well on macCatalyst.
            //  So we handle single / double tap gesture simultaneous
            //  1. deliver single tap without delay
            //  2. deliver double tap if triggered
            //  3. cancel second single tap if double tap emitted within 100ms tolerance
        }
    }
}

#if DEBUG
struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        if let authContext = AuthContext.mock(context: .shared) {
            SidebarView(viewModel: SidebarViewModel(context: .shared, authContext: authContext))
                .previewLayout(.fixed(width: 80, height: 800))
        }
    }
}
#endif

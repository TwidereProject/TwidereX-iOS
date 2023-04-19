//
//  CoverFlowStackScrollView.swift
//  
//
//  Created by MainasuK on 2023/4/17.
//

import SwiftUI
import UIKit


// Seealso: Example.SwiftUIViewController
public struct CoverFlowStackScrollView<Content: View>: View {
    
    let id = UUID()
    let content: () -> Content
    let contentOffsetDidUpdate: (CGFloat) -> Void
    let contentSizeDidUpdate: (CGSize) -> Void
    
    public init(
        @ViewBuilder _ content: @escaping () -> Content,
        contentOffsetDidUpdate: @escaping (CGFloat) -> Void,
        contentSizeDidUpdate: @escaping (CGSize) -> Void
    ) {
        self.content = content
        self.contentOffsetDidUpdate = contentOffsetDidUpdate
        self.contentSizeDidUpdate = contentSizeDidUpdate
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            offsetReader
            content()
                .background(GeometryReader{ proxy in
                    Color.clear.preference(key: SizePreferenceKey.self, value: proxy.size)
                        .onPreferenceChange(SizePreferenceKey.self) { size in
                            contentSizeDidUpdate(size)
                        }
                })
        }
        .coordinateSpace(name: id.uuidString)
        .onPreferenceChange(OffsetPreferenceKey.self) { offset in
            contentOffsetDidUpdate(offset)
        }
    }
    
    var offsetReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: OffsetPreferenceKey.self,
                    value: proxy.frame(in: .named(id.uuidString)).minX
                )
        }
        .frame(height: .leastNonzeroMagnitude)
    }
}

private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) { }
}

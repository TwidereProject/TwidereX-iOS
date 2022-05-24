//
//  ReorderableForEach.swift
//  
//
//  Created by MainasuK on 2022-5-23.
//

import SwiftUI
import UniformTypeIdentifiers

// Ref
// https://stackoverflow.com/a/68963988/3797903

struct ReorderableForEach<Content: View, Item: Identifiable & Equatable & NSItemProviderWriting & TypeIdentifiedItemProvider>: View {

    @State var currentReorderItem: Item? = nil
    @State var isCurrentReorderItemOutside: Bool = false

    let items: [Item]
    let content: (Item) -> Content
    let moveAction: (IndexSet, Int) -> Void

    var body: some View {
        ForEach(items) { item in
            content(item)
                .zIndex(currentReorderItem == item ? 1 : 0)
                // .opacity(currentReorderItem == item && !isCurrentReorderItemOutside ? 0.5 : 1.0)
                .onDrop(
                    of: [Item.typeIdentifier],
                    delegate: DropRelocateDelegate(
                        item: item,
                        listData: items,
                        current: $currentReorderItem,
                        isOutside: $isCurrentReorderItemOutside
                    ) { from, to in
                        withAnimation {
                            moveAction(from, to)
                        }
                    }
                )
                .onDrag {
                    currentReorderItem = item
                    isCurrentReorderItemOutside = false
                    return NSItemProvider(object: item)
                }
        }
        .contentShape(Rectangle())
        .onDrop(
            of: [Item.typeIdentifier],
            delegate: DropOutsideDelegate(
                current: $currentReorderItem,
                isOutside: $isCurrentReorderItemOutside
            )
        )
    }
}

struct DropRelocateDelegate<Item: Equatable>: DropDelegate {
    let item: Item
    var listData: [Item]
    
    @Binding var current: Item?
    @Binding var isOutside: Bool

    var moveAction: (IndexSet, Int) -> Void

    func dropEntered(info: DropInfo) {
        guard item != current, let current = current else { return }
        guard let from = listData.firstIndex(of: current), let to = listData.firstIndex(of: item) else { return }
        
        if listData[to] != current {
            moveAction(IndexSet(integer: from), to > from ? to + 1 : to)
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        current = nil
        isOutside = false
        return true
    }
}

struct DropOutsideDelegate<Item: Equatable>: DropDelegate {
    @Binding var current: Item?
    @Binding var isOutside: Bool
    
    func dropEntered(info: DropInfo) {
        isOutside = false
    }
    
    func dropExited(info: DropInfo) {
        isOutside = true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .cancel)
    }
        
    func performDrop(info: DropInfo) -> Bool {
        current = nil
        isOutside = false
        return true
    }
}

public protocol TypeIdentifiedItemProvider {
    static var typeIdentifier: String { get }
}

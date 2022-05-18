//
//  StatusViewPresentable.swift
//  
//
//  Created by MainasuK on 2022-5-18.
//

import UIKit
import SwiftUI
import TwidereUI

public struct ComposeReplyTableViewCellPresentable: UIViewRepresentable {
    
    
    public func makeUIView(context: Context) -> ComposeReplyTableViewCell {
        let cell = ComposeReplyTableViewCell()
        return cell
    }
    
    public func updateUIView(_ cell: ComposeReplyTableViewCell, context: Context) {
        cell.statusView.viewModel.authorUsername = "Hi"
    }
    
}

#if DEBUG
struct ComposeReplyTableViewCellPresentable_Preview: PreviewProvider {
    static var previews: some View {
        ComposeReplyTableViewCellPresentable()
    }
}
#endif

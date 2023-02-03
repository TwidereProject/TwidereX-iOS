//
//  StatusHeaderView.swift
//  
//
//  Created by MainasuK on 2023/2/3.
//

import SwiftUI
import TwidereAsset
import TwidereLocalization

public struct StatusHeaderView: View {
    
    @ObservedObject public var viewModel: ViewModel
    
    public var body: some View {
        Text("Repost")
    }
    
}

extension StatusHeaderView {
    public class ViewModel: ObservableObject {
        @Published public var label: AttributedString
        
        public init(label: AttributedString) {
            self.label = label
        }
    }
}

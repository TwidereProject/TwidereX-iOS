//
//  EmptyStateView.swift
//  
//
//  Created by MainasuK on 2023-06-20.
//

import UIKit
import SwiftUI
import TwidereCore

public struct EmptyStateView: View {
    @ObservedObject public var viewModel: ViewModel
    
    public init(viewModel: EmptyStateView.ViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack {
            Spacer()
            Spacer()
            Spacer()
            VStack {
                if let iconSystemName = viewModel.iconSystemName {
                    Image(systemName: iconSystemName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .foregroundColor(.secondary)
                        .font(.title)
                        .opacity(0.5)
                }
                if let title = viewModel.title {
                    Text(verbatim: title)
                        .foregroundColor(.secondary)
                        .font(.headline)
                }
                if let subtitle = viewModel.subtitle {
                    Text(verbatim: subtitle)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
            Spacer()
            Spacer()
            Spacer()
            Spacer()
        }
    }
}

extension EmptyStateView {
    public class ViewModel: ObservableObject {
        // input
        @Published public var emptyState: EmptyState?
        
        // ouptut
        var iconSystemName: String? {
            emptyState?.iconSystemName
        }
        var title: String? {
            emptyState?.title
        }
        var subtitle: String? {
            emptyState?.subtitle
        }
        
        public init(emptyState: EmptyState? = nil) {
            self.emptyState = emptyState
            // end init
        }
    }
}

struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateView(viewModel: .init(emptyState: .noResults))
        EmptyStateView(viewModel: .init(emptyState: .unableToAccess()))
            
    }
}

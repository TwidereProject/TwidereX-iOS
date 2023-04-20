//
//  TimestampLabelView.swift
//  
//
//  Created by MainasuK on 2023/2/21.
//

import SwiftUI
import Combine
import Meta
import TwidereCore
import DateToolsSwift

public struct TimestampLabelView: View {
    
    @ObservedObject public var viewModel: ViewModel
    
    public init(viewModel: TimestampLabelView.ViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
            let timeAgo = viewModel.timeAgo(now: timeline.date)
            Text("\(timeAgo)")
                .font(Font(TextStyle.statusTimestamp.font).monospacedDigit())
                .foregroundColor(Color(uiColor: TextStyle.statusTimestamp.textColor))
        }
    }
}

extension TimestampLabelView {
    public class ViewModel: ObservableObject {
        // input
        public let timestamp: Date
        
        public init(timestamp: Date) {
            self.timestamp = timestamp
            // end init
        }
        
        func timeAgo(now: Date) -> String {
            return timestamp.shortTimeAgo(since: now)
        }
        
    }   // end class
}

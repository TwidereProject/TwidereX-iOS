//
//  StatusContentView.swift
//  TwidereX
//
//  Created by MainasuK Cirno on 2021-7-13.
//  Copyright © 2021 Twidere. All rights reserved.
//

import SwiftUI
import Meta

struct StatusContentView: View {

    @ScaledMetric(relativeTo: .body) var labelFontSize: CGFloat = 14.0
    @StateObject var statusTextAreaViewModel = StatusTextAreaViewModel()

    let content: MetaContent?

    init(status: Status?) {
        self.content = status?.metaContent
    }

    var body: some View {
        GeometryReader { proxy in
            StatusTextArea(
                content: content,
                width: proxy.size.width,
                viewModel: statusTextAreaViewModel
            )
        }
        .frame(height: statusTextAreaViewModel.height)
    }
}

struct StatusContentView_Previews: PreviewProvider {

    static var attributedString: AttributedString {
        var attributedString = AttributedString("Hello, World!")
        if let range = attributedString.range(of: "Hello") {
            attributedString[range].imageURL = URL(string: "https://media.mstdn.jp/custom_emojis/images/000/000/783/original/eabe84867ef24f6d.png")
        }
        return attributedString
    }
    static var previews: some View {
        Group {
            StatusContentView(status: Sample.status)
                .previewLayout(.sizeThatFits)
        }
    }
}


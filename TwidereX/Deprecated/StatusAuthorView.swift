//
//  StatusAuthorView.swift
//  TwidereX
//
//  Created by MainasuK Cirno on 2021-7-12.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import SwiftUI
import DateToolsSwift

struct StatusAuthorView: View {

    @ScaledMetric(relativeTo: .headline) var labelFontSize: CGFloat = 14.0

    let name: String
    let username: String
    let timestamp: Date

    init(status: Status?) {
        let status = status?.repost ?? status
        let author = status?.account
        self.name = author?.name ?? "-"
        self.username = "@" + (author?.username ?? "-")
        self.timestamp = status?.createdAt ?? Date()
    }

    var body: some View {
        HStack {
            Text(name)
                .font(Font.system(size: labelFontSize, weight: .medium, design: .default))
                .layoutPriority(998)
            Text(username)
                .font(Font.system(size: labelFontSize, weight: .regular, design: .default))
                .foregroundColor(.secondary)
            Spacer()
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                Text(timestamp.shortTimeAgoSinceNow)
                    .font(Font.system(size: labelFontSize, weight: .regular, design: .default).monospacedDigit())
                    .foregroundColor(.secondary)
                    .layoutPriority(999)
            }
        }
        .lineLimit(1)
    }
}

struct StatusAuthorView_Previews: PreviewProvider {
    static var previews: some View {
        StatusAuthorView(status: Sample.status)
            .previewLayout(.sizeThatFits)
    }
}


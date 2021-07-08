//
//  HomeTimelineView.swift
//  TwidereX
//
//  Created by MainasuK Cirno on 2021-7-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import SwiftUI
import Kingfisher

struct HomeTimelineView: View {

    @ScaledMetric(relativeTo: .headline) var avatarSize: CGFloat = 44

    @FetchRequest(
        sortDescriptors: TimelineIndex.defaultSortDescriptors,
        predicate: nil,
        animation: nil
    )
    var indexes: FetchedResults<TimelineIndex>

    var body: some View {
        List {
            ForEach(indexes, id: \.self) { index in
                HStack {
                    AsyncImage(url: index.tweet?.author.avatarImageURL()) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .transition(.opacity)
                        case .failure, .empty:
                            Color.gray
                        @unknown default:
                            Color.gray
                        }
                    }
                    .clipShape(Circle())
                    .frame(width: avatarSize, height: avatarSize)
                    Spacer(minLength: 10)
                    KFImage(index.tweet?.author.avatarImageURL())
                        .placeholder {
                            Color.gray
                        }
                        .cacheOriginalImage()
                        .fade(duration: 0.2)
                        .forceTransition()
                        .resizable()
                        .frame(width: avatarSize, height: avatarSize)
                        .clipShape(Circle())
                    Spacer()
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct HomeTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        HomeTimelineView()
    }
}

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

    @ScaledMetric(relativeTo: .headline) var _avatarSize: CGFloat = 44.0
    var avatarSize: CGFloat {
        return max(44.0, min(88.0, _avatarSize))
    }

    @FetchRequest(
        sortDescriptors: TimelineIndex.defaultSortDescriptors,
        predicate: nil,
        animation: nil
    )
    var indexes: FetchedResults<TimelineIndex>

    var body: some View {
        List {
            ForEach(indexes, id: \.self) { index in
                let avatarImageURL = index.tweet?.author.avatarImageURL()
                let name = index.tweet?.author.name ?? "-"
                let username = index.tweet?.author.username ?? "-"
                let content = index.tweet?.text ?? ""
                let media = Array((index.tweet?.retweet ?? index.tweet)?.media ?? []).sorted { $0.index.compare($1.index) == .orderedAscending }
                let imageMedia = media.filter { $0.type == "photo" }
                HStack(alignment: .top) {
                    KFImage(avatarImageURL)
                        .placeholder {
                            Color.gray
                        }
                        .cacheOriginalImage()
                        .cancelOnDisappear(true)
                        .fade(duration: 0.2)
                        .forceTransition()
                        .resizable()
                        .frame(width: avatarSize, height: avatarSize)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading) {
                            Text(name)
                                .font(.headline)
                            Text("@" + username)
                                .font(.subheadline)
                        }
                        Text(content)
                            .font(.body)
                        ForEach(imageMedia, id: \.id) { media in
                            let photoURL = media.url.flatMap { URL(string: $0) }
                            let aspectRatio: CGFloat? = {
                                guard let width = media.width?.intValue,
                                      let height = media.height?.intValue else { return nil }
                                return CGFloat(width) / CGFloat(height)
                            }()
                            KFImage(photoURL)
                                .placeholder {
                                    Color.gray
                                }
                                .cacheOriginalImage()
                                .cancelOnDisappear(true)
                                .fade(duration: 0.2)
                                .forceTransition()
                                .resizable()
                                .aspectRatio(aspectRatio, contentMode: .fit)
                                .frame(maxHeight: floor(UIScreen.main.bounds.height / 3))
                                .cornerRadius(10)
                                .onTapGesture(count: 1) {
                                    let photoURLString = photoURL?.absoluteString ?? "<nil>"
                                    print("image: \(photoURLString)")
                                }
                        }
                    }
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

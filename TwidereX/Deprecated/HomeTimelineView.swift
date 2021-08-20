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

    @FetchRequest(
        sortDescriptors: TimelineIndex.defaultSortDescriptors,
        predicate: nil,
        animation: nil
    ) var indexes: FetchedResults<TimelineIndex>

    var body: some View {
        List {
            ForEach(indexes, id: \.objectID) { index in
                StatusSwiftUIView(status: index.tweet!)
//                let media = Array((index.tweet?.retweet ?? index.tweet)?.media ?? []).sorted { $0.index.compare($1.index) == .orderedAscending }
//                let imageMedia = media.filter { $0.type == "photo" }
//                HStack(alignment: .top) {
//                    VStack(alignment: .leading, spacing: 10) {
//                        ForEach(imageMedia, id: \.id) { media in
//                            let photoURL = media.url.flatMap { URL(string: $0) }
//                            let aspectRatio: CGFloat? = {
//                                guard let width = media.width?.intValue,
//                                      let height = media.height?.intValue else { return nil }
//                                return CGFloat(width) / CGFloat(height)
//                            }()
//                            KFImage(photoURL)
//                                .placeholder {
//                                    Color(uiColor: .systemFill)
//                                }
//                                .cacheOriginalImage()
//                                .cancelOnDisappear(true)
//                                .fade(duration: 0.2)
//                                .forceTransition()
//                                .resizable()
//                                .aspectRatio(aspectRatio, contentMode: .fill)
//                                .frame(maxHeight: floor(UIScreen.main.bounds.height / 3))
//                                .cornerRadius(10)
//                                .onTapGesture(count: 1) {
//                                    let photoURLString = photoURL?.absoluteString ?? "<nil>"
//                                    print("image: \(photoURLString)")
//                                }
//                        }   // end ForEach
//                    }   // end HStack
//                }
            }
        }   // end List
        .listStyle(PlainListStyle())
    }   // end body
}

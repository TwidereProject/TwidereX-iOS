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

struct HomeTimelineView: View {

    @FetchRequest(
        sortDescriptors: TimelineIndex.defaultSortDescriptors,
        predicate: nil,
        animation: nil
    )
    var indexes: FetchedResults<TimelineIndex>

    var body: some View {
        List {
            ForEach(indexes, id: \.self) { index in
                Text("\(index.identifier)")
            }
        }
    }
}

struct HomeTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        HomeTimelineView()
    }
}

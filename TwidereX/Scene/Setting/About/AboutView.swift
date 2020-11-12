//
//  AboutView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-12.
//  Copyright © 2020 Twidere. All rights reserved.
//

import SwiftUI

enum AboutEntryType: Hashable {
    case github
}

struct AboutView: View {
    
    @EnvironmentObject var context: AppContext
    
    var body: some View {
        List {
            Section(header: Text("")) {
                Button(action: {
                    context.viewStateStore.aboutView.aboutEntryPublisher.send(.github)
                }, label: {
                    TableViewEntryRow(icon: nil, title: "GitHub")
                        .foregroundColor(Color(.label))
                })
            }
        }
        .listStyle(GroupedListStyle())
    }
    
}

#if DEBUG

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AboutView()
            AboutView()
                .preferredColorScheme(.dark)
        }
    }
}

#endif

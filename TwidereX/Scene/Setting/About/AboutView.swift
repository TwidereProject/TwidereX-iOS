//
//  AboutView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-12.
//  Copyright © 2020 Twidere. All rights reserved.
//

import SwiftUI

enum AboutEntryType: Identifiable, Hashable, CaseIterable {
    
    case github
    case twitter
    
    var id: AboutEntryType { return self }
    var title: String {
        switch self {
        case .github:       return "GitHub"
        case .twitter:      return "Twitter"
        }
    }
    
}

struct AboutView: View {
    
    @EnvironmentObject var context: AppContext
    
    var body: some View {
        List {
            Section(
                header:
                    VStack {
                        Image(uiImage: Asset.Logo.twidere.image)
                        Text("Twidere X")
                            .font(.system(size: 24))
                        Text(UIApplication.versionBuild())
                            .font(.system(size: 16))
                    }
                    .modifier(TextCaseEraseStyle())
                    .frame(maxWidth: .infinity)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0))
            ) {
                ForEach(AboutEntryType.allCases) { entry in
                    Button(action: {
                        context.viewStateStore.aboutView.aboutEntryPublisher.send(entry)
                    }, label: {
                        TableViewEntryRow(icon: nil, title: entry.title)
                            .foregroundColor(Color(.label))
                    })
                }
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

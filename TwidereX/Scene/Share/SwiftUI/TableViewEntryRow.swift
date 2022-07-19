//
//  TableViewEntryRow.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-12.
//  Copyright © 2020 Twidere. All rights reserved.
//

import SwiftUI

struct TableViewEntryRow: View {
    
    let icon: Image?
    let title: String
    let accessorySymbolName: String?
    
    init(
        icon: Image? = nil,
        title: String,
        accessorySymbolName: String? = "chevron.right"
    ) {
        self.icon = icon
        self.title = title
        self.accessorySymbolName = accessorySymbolName
    }
    
    var body: some View {
        HStack {
            if let icon = icon {
                icon.renderingMode(.template)
            }
            Text(title)
            Spacer()
            if let name = accessorySymbolName {
                Image(systemName: name)
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
    }
    
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct TableViewEntryRow_Previews: PreviewProvider {
    static var previews: some View {
        TableViewEntryRow(icon: Image(systemName: "human"), title: "Human")
    }
}

#endif


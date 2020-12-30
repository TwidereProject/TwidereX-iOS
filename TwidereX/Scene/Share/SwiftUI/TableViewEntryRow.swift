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
    
    var body: some View {
        HStack {
            if let icon = icon {
                icon.renderingMode(.template)
            }
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(Color(.secondaryLabel))
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


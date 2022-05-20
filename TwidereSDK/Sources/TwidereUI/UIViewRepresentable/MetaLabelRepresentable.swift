//
//  MetaLabelRepresentable.swift
//  
//
//  Created by MainasuK on 2022-5-19.
//

import UIKit
import SwiftUI
import TwidereCore
import MetaTextKit

public struct MetaLabelRepresentable: UIViewRepresentable {
    
    let textStyle: TextStyle
    let metaContent: MetaContent
    
    public func makeUIView(context: Context) -> MetaLabel {
        let view = MetaLabel(style: textStyle)
        return view
    }
    
    public func updateUIView(_ view: MetaLabel, context: Context) {
        view.configure(content: metaContent)
    }
    
}

#if DEBUG
struct MetaLabelRepresentable_Preview: PreviewProvider {
    static var previews: some View {
        MetaLabelRepresentable(
            textStyle: .userAuthorName,
            metaContent: PlaintextMetaContent(string: "Name")
        )
    }
}
#endif

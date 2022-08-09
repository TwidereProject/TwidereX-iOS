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
import MetaLabel

public struct MetaLabelRepresentable: UIViewRepresentable {
    
    public let textStyle: TextStyle
    public let metaContent: MetaContent
    
    public init(
        textStyle: TextStyle,
        metaContent: MetaContent
    ) {
        self.textStyle = textStyle
        self.metaContent = metaContent
    }
    
    public func makeUIView(context: Context) -> MetaLabel {
        let view = MetaLabel(style: textStyle)
        view.isUserInteractionEnabled = false
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

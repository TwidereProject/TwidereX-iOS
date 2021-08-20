//
//  StatusTextArea.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-7-30.
//

import UIKit
import Combine
import SwiftUI
import MetaTextArea
import Meta

class StatusTextAreaViewModel: ObservableObject {
    @Published var height: CGFloat = 44.0
}

struct StatusTextArea: UIViewRepresentable {
    
    var disposeBag = Set<AnyCancellable>()
    
    public let content: MetaContent?
    public let width: CGFloat
    public let viewModel: StatusTextAreaViewModel
    
    func makeUIView(context: Context) -> MetaTextAreaView {
        let view = MetaTextAreaView()
        view.delegate = context.coordinator
            
        let string = content?.string.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let attributedString = NSAttributedString(string: string, attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body)
        ])
        view.textContentStorage.textStorage?.setAttributedString(attributedString)
    
        return view
    }
    
    func updateUIView(_ view: MetaTextAreaView, context: Context) {
        view.maxWidth = width
        view.updateTextContainerSize()
    }
    
    static func dismantleUIView(_ view: MetaTextAreaView, coordinator: Coordinator) {
        view.delegate = nil
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: MetaTextAreaViewDelegate {
        let textArea: StatusTextArea
                
        init(_ textArea: StatusTextArea) {
            self.textArea = textArea
        }
        
        func metaTextAreaView(_ view: MetaTextAreaView, intrinsicContentSizeDidUpdate size: CGSize) {
            self.textArea.viewModel.height = ceil(size.height)
        }
    }
    
}

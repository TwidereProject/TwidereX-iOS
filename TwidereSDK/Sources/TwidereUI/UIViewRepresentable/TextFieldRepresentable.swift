//
//  TextFieldRepresentable.swift
//  
//
//  Created by MainasuK on 2022-5-31.
//

import os.log
import UIKit
import SwiftUI
import Combine
import TwidereCore

public struct TextFieldRepresentable: UIViewRepresentable {
    
    let textField = UITextField()

    @Binding var text: String
    
    public func makeUIView(context: Context) -> UITextField {
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textField
    }
    
    public func updateUIView(_ textField: UITextField, context: Context) {
        
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
}

extension TextFieldRepresentable {
    public class Coordinator: NSObject {
        let logger = Logger(subsystem: "TextFieldRepresentable.Coordinator", category: "Coordinator")
        
        var disposeBag = Set<AnyCancellable>()

        let view: TextFieldRepresentable
        
        init(_ view: TextFieldRepresentable) {
            self.view = view
            super.init()
            
            NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: view.textField)
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    self.view.text = view.textField.text ?? ""
                }
                .store(in: &disposeBag)
        }
    }
}

// MARK: - UITextFieldDelegate
extension TextFieldRepresentable.Coordinator: UITextFieldDelegate {

}

#if DEBUG
struct TextFieldRepresentable_Preview: PreviewProvider {
    static var previews: some View {
        TextFieldRepresentable(text: .constant(""))
    }
}
#endif

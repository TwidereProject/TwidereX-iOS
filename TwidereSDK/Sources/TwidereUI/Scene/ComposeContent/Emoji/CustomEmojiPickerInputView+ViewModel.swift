//
//  CustomEmojiPickerInputView+ViewModel.swift
//  
//
//  Created by MainasuK on 2021-11-28.
//

import UIKit
import Combine
import MetaTextKit

public protocol CustomEmojiReplaceableTextInput: UITextInput & UIResponder {
    var inputView: UIView? { get set }
}

public class CustomEmojiReplaceableTextInputReference {
    weak var value: CustomEmojiReplaceableTextInput?

    public init(value: CustomEmojiReplaceableTextInput? = nil) {
        self.value = value
    }
}

extension UITextField: CustomEmojiReplaceableTextInput { }
extension UITextView: CustomEmojiReplaceableTextInput { }

extension CustomEmojiPickerInputView {
    public final class ViewModel {
        
        var disposeBag = Set<AnyCancellable>()
        
        private var customEmojiReplaceableTextInputReferences: [CustomEmojiReplaceableTextInputReference] = []
        
        // input
        weak var customEmojiPickerInputView: CustomEmojiPickerInputView?
        
        // output
        let isCustomEmojiComposing = CurrentValueSubject<Bool, Never>(false)
        
        public init() { }
        
    }
}

extension CustomEmojiPickerInputView.ViewModel {
    public func configure(textInput: CustomEmojiReplaceableTextInput) {
        isCustomEmojiComposing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isCustomEmojiComposing in
                guard let self = self else { return }
                textInput.inputView = isCustomEmojiComposing ? self.customEmojiPickerInputView : nil
                textInput.reloadInputViews()
                self.append(customEmojiReplaceableTextInput: textInput)
            }
            .store(in: &disposeBag)
    }
}

extension CustomEmojiPickerInputView.ViewModel {
    
    private func removeEmptyReferences() {
        customEmojiReplaceableTextInputReferences.removeAll(where: { element in
            element.value == nil
        })
    }
    
    func append(customEmojiReplaceableTextInput textInput: CustomEmojiReplaceableTextInput) {
        removeEmptyReferences()
        
        let isContains = customEmojiReplaceableTextInputReferences.contains(where: { element in
            element.value === textInput
        })
        guard !isContains else {
            return
        }
        customEmojiReplaceableTextInputReferences.append(CustomEmojiReplaceableTextInputReference(value: textInput))
    }
    
    func insertText(_ text: String) -> CustomEmojiReplaceableTextInputReference? {
        removeEmptyReferences()
        
        for reference in customEmojiReplaceableTextInputReferences {
            guard let textInput = reference.value else { continue }
            guard textInput.isFirstResponder == true else { continue }
            guard let selectedTextRange = textInput.selectedTextRange else { continue }

            textInput.insertText(text)

            // TODO:
            
            // due to insert text render as attachment
            // the cursor reset logic not works
            // hack with hard code +2 offset
            // assert(text.hasSuffix(": "))
            // guard text.hasPrefix(":") && text.hasSuffix(": ") else { continue }
            //
            // if let _ = textInput as? MetaTextView {
            //     if let newPosition = textInput.position(from: selectedTextRange.start, offset: 2) {
            //         let newSelectedTextRange = textInput.textRange(from: newPosition, to: newPosition)
            //         textInput.selectedTextRange = newSelectedTextRange
            //     }
            // } else {
            //     let length = (text as NSString).length
            //     if let newPosition = textInput.position(from: selectedTextRange.start, offset: length) {
            //         let newSelectedTextRange = textInput.textRange(from: newPosition, to: newPosition)
            //         textInput.selectedTextRange = newSelectedTextRange
            //     }
            // }

            return reference
        }
        
        return nil
    }
    
}


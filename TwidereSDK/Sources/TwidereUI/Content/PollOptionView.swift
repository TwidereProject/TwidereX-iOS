//
//  PollOptionView.swift
//  
//
//  Created by MainasuK on 2021-11-29.
//

import UIKit
import MetaTextKit
import TwidereLocalization
import UITextView_Placeholder
import TwidereCore

public protocol PollOptionViewDelegate: AnyObject {
    func pollOptionView(_ pollOptionView: PollOptionView, deleteBackwardResponseTextField textField: DeleteBackwardResponseTextField, textBeforeDelete: String?)
}

public final class PollOptionView: UIView {
    
    public weak var delegate: PollOptionViewDelegate?
    private var style: Style?
    
    let containerView = UIView()
    
    // TODO: MetaTextField?
    public let textField: DeleteBackwardResponseTextField = {
        let textField = DeleteBackwardResponseTextField()
        textField.font = .systemFont(ofSize: 16, weight: .regular)
        textField.textColor = .label
        textField.text = "Choice" // TODO: i18n
        textField.textAlignment = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight ? .left : .right
        return textField
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension PollOptionView {
    
    private func _init() {
        textField.deleteBackwardDelegate = self
    }
    
    public func setup(style: Style) {
        guard self.style == nil else {
            assertionFailure("Should only setup once")
            return
        }
        self.style = style
        style.layout(view: self)
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            textField.layer.borderColor = UIColor.secondaryLabel.cgColor
        }
    }
    
}

extension PollOptionView {
    public enum Style {
        case plain
        case edit
        
        func layout(view: PollOptionView) {
            switch self {
            case .plain:        layoutPlain(view: view)
            case .edit:         layoutEdit(view: view)
            }
        }
    }
}

extension PollOptionView.Style {
    private func layoutPlain(view: PollOptionView) {
        assertionFailure()
        // TODO:
    }
    
    private func layoutEdit(view: PollOptionView) {
        view.containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(view.containerView)
        NSLayoutConstraint.activate([
            view.containerView.topAnchor.constraint(equalTo: view.topAnchor),
            view.containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        view.textField.translatesAutoresizingMaskIntoConstraints = false
        view.containerView.addSubview(view.textField)
        NSLayoutConstraint.activate([
            view.textField.topAnchor.constraint(equalTo: view.containerView.topAnchor),
            view.textField.leadingAnchor.constraint(equalTo: view.containerView.leadingAnchor),
            view.textField.trailingAnchor.constraint(equalTo: view.containerView.trailingAnchor),
            view.textField.bottomAnchor.constraint(equalTo: view.containerView.bottomAnchor),
        ])
        
        view.containerView.layer.masksToBounds = true
        view.containerView.layer.cornerRadius = 6
        view.containerView.layer.cornerCurve = .continuous
        view.containerView.layer.borderColor = UIColor.secondaryLabel.cgColor
        view.containerView.layer.borderWidth = UIView.separatorLineHeight(of: view)
    }
    
}

// MARK; - DeleteBackwardResponseTextFieldDelegate
extension PollOptionView: DeleteBackwardResponseTextFieldDelegate {
    public func deleteBackwardResponseTextField(_ textField: DeleteBackwardResponseTextField, textBeforeDelete: String?) {
        delegate?.pollOptionView(self, deleteBackwardResponseTextField: textField, textBeforeDelete: textBeforeDelete)
    }
}

#if DEBUG
import SwiftUI
struct PollOptionView_Preview: PreviewProvider {
    static var previews: some View {
        UIViewPreview {
            let pollOptionView = PollOptionView()
            pollOptionView.setup(style: .edit)
            return pollOptionView
        }
    }
}
#endif

//
//  ComposePollOptionCollectionViewCell.swift
//  
//
//  Created by MainasuK on 2021-11-29.
//

import os.log
import UIKit
import TwidereUI

public protocol ComposePollOptionCollectionViewCellDelegate: AnyObject {
    func composePollOptionCollectionViewCell(_ cell: ComposePollOptionCollectionViewCell, textFieldDidBeginEditing textField: UITextField)
    func composePollOptionCollectionViewCell(_ cell: ComposePollOptionCollectionViewCell, textFieldDidReturn textField: UITextField)
    func composePollOptionCollectionViewCell(_ cell: ComposePollOptionCollectionViewCell, textField: DeleteBackwardResponseTextField, textBeforeDelete: String?)
}

public final class ComposePollOptionCollectionViewCell: UICollectionViewCell {
    
    static var height: CGFloat = 44 + 2 * 5
    
    public weak var delegate: ComposePollOptionCollectionViewCellDelegate?

    let logger = Logger(subsystem: "ComposePollOptionCollectionViewCell", category: "Cell")
    public let pollOptionView = PollOptionView()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ComposePollOptionCollectionViewCell {
    
    private func _init() {
        pollOptionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pollOptionView)
        NSLayoutConstraint.activate([
            pollOptionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            pollOptionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pollOptionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: pollOptionView.bottomAnchor, constant: 5),
            pollOptionView.heightAnchor.constraint(equalToConstant: 44).priority(.required - 1),
        ])
        
        pollOptionView.textField.textInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        pollOptionView.setup(style: .edit)
        
        pollOptionView.textField.delegate = self
        pollOptionView.delegate = self
    }
    
}

// MARK: - UITextFieldDelegate
extension ComposePollOptionCollectionViewCell: UITextFieldDelegate {
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        assert(textField === pollOptionView.textField)
        delegate?.composePollOptionCollectionViewCell(self, textFieldDidBeginEditing: textField)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        assert(textField === pollOptionView.textField)
        delegate?.composePollOptionCollectionViewCell(self, textFieldDidReturn: textField)
        
        return true
    }
}

// MARK: - PollOptionViewDelegate
extension ComposePollOptionCollectionViewCell: PollOptionViewDelegate {
    public func pollOptionView(_ pollOptionView: PollOptionView, deleteBackwardResponseTextField textField: DeleteBackwardResponseTextField, textBeforeDelete: String?) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        delegate?.composePollOptionCollectionViewCell(self, textField: textField, textBeforeDelete: textBeforeDelete)
    }
}

//
//  PollOptionTableViewCell.swift
//  
//
//  Created by MainasuK on 2021-12-8.
//

import UIKit

public final class PollOptionTableViewCell: UITableViewCell {
    
    public static let margin: CGFloat = 4
    public static let height: CGFloat = 2 * margin + PollOptionView.height
    
    public let optionView = PollOptionView()
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        optionView.disposeBag.removeAll()
        optionView.prepareForReuse()
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

    public override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        optionView.alpha = highlighted ? 0.5 : 1
    }
    
}

extension PollOptionTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = .clear
        
        optionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(optionView)
        NSLayoutConstraint.activate([
            optionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: PollOptionTableViewCell.margin),
            optionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            optionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo:  optionView.bottomAnchor, constant: PollOptionTableViewCell.margin),
            optionView.heightAnchor.constraint(equalToConstant: PollOptionView.height).priority(.required - 1),
        ])
        optionView.setup(style: .plain)
        
        // accessibility
        accessibilityElements = [optionView]
        optionView.isAccessibilityElement = true
        
    }
    
}

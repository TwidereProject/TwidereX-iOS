//
//  StatusTableViewCell.swift
//  StatusTableViewCell
//
//  Created by Cirno MainasuK on 2021-8-20.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

public class StatusTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let logger = Logger(subsystem: "StatusTableViewCell", category: "View")
    
    public weak var statusViewTableViewCellDelegate: StatusViewTableViewCellDelegate?
    
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        statusViewTableViewCellDelegate = nil
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension StatusTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        
        ThemeService.shared.$theme
            .map { $0.background }
            .assign(to: \.backgroundColor, on: self)
            .store(in: &disposeBag)
    }
    
}

// MARK: - StatusViewContainerTableViewCell
extension StatusTableViewCell: StatusViewContainerTableViewCell { }

// MARK: - StatusViewDelegate
extension StatusTableViewCell: StatusViewDelegate { }

//
//  TrendTableViewCell.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-28.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine

final class TrendTableViewCell: UITableViewCell {
    
    private var _disposeBag = Set<AnyCancellable>()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        contentConfiguration = nil
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

extension TrendTableViewCell {
    
    private func _init() {
        // theme
        ThemeService.shared.$theme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setup(theme: theme)
            }
            .store(in: &_disposeBag)
    }
    
    func setup(theme: Theme) {
        backgroundColor = theme.background
        contentView.backgroundColor = theme.foreground.withAlphaComponent(0.04)
    }
    
}

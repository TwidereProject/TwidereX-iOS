//
//  DrawerSidebarEntryTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-9.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class DrawerSidebarEntryTableViewCell: UITableViewCell {
    
    let entryView = DrawerSidebarEntryView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension DrawerSidebarEntryTableViewCell {
    
    private func _init() {
        entryView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(entryView)
        NSLayoutConstraint.activate([
            entryView.topAnchor.constraint(equalTo: contentView.topAnchor),
            entryView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: entryView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: entryView.bottomAnchor),
        ])
    }
    
}

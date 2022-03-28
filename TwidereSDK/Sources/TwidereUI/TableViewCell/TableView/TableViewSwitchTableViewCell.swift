//
//  TableViewSwitchTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-19.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

public final class TableViewSwitchTableViewCell: UITableViewCell {
    
    public var disposeBag = Set<AnyCancellable>()
    
    let switcher = UISwitch()
    let switcherPublisher = PassthroughSubject<Bool, Never>()
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TableViewSwitchTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        accessoryView = switcher
        
        switcher.addTarget(self, action: #selector(TableViewSwitchTableViewCell.switchToggled(_:)), for: .valueChanged)
    }
    
}

extension TableViewSwitchTableViewCell {

    @objc private func switchToggled(_ sender: UIEvent) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        switcherPublisher.send(switcher.isOn)
    }
    
}

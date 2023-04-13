//
//  TableSlideTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-19.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

public final class TableSlideTableViewCell: UITableViewCell {
    
    public var disposeBag = Set<AnyCancellable>()
    
    let container = UIStackView()
    let leadingLabel = UILabel()
    let trailingLabel = UILabel()
    let slider = UISlider()
    
    public let sliderPublisher = PassthroughSubject<Float, Never>()
    
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

extension TableSlideTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        
        container.axis = .horizontal
        container.spacing = 8
        
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            container.heightAnchor.constraint(equalToConstant: 44).priority(.required - 1),
        ])
        
        container.addArrangedSubview(leadingLabel)
        container.addArrangedSubview(slider)
        container.addArrangedSubview(trailingLabel)

        slider.addTarget(self, action: #selector(TableSlideTableViewCell.sliderValueChagned(_:event:)), for: .valueChanged)
    }
    
}

extension TableSlideTableViewCell {
    
    @objc private func sliderValueChagned(_ sender: UISlider, event: UIEvent) {
        sliderPublisher.send(sender.value)
    }
    
}

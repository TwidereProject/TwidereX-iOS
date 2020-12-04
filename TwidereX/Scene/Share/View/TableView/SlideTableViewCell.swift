//
//  SlideTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-19.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

final class SlideTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let container = UIStackView()
    let leadingLabel = UILabel()
    let trailingLabel = UILabel()
    let slider = UISlider()
    
    let sliderPublisher = PassthroughSubject<Float, Never>()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
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

extension SlideTableViewCell {
    
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

        slider.addTarget(self, action: #selector(SlideTableViewCell.sliderValueChagned(_:event:)), for: .valueChanged)
    }
    
}

extension SlideTableViewCell {
    
    @objc private func sliderValueChagned(_ sender: UISlider, event: UIEvent) {
        sliderPublisher.send(sender.value)
    }
    
}

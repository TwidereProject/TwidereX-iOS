//
//  TimelineBottomLoaderCollectionViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-8.
//

import UIKit

final class TimelineBottomLoaderCollectionViewCell: UICollectionViewCell {
    
    let loadMoreButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .systemFont(ofSize: 13)
        button.setTitle("Load More…", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.setTitleColor(UIColor.systemBlue.withAlphaComponent(0.5), for: .highlighted)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TimelineBottomLoaderCollectionViewCell {
    
    private func _init() {
        loadMoreButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(loadMoreButton)
        NSLayoutConstraint.activate([
            loadMoreButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            loadMoreButton.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: loadMoreButton.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: loadMoreButton.bottomAnchor, constant: 8),
        ])
    }
    
}


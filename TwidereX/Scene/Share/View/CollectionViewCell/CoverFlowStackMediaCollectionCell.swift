//
//  CoverFlowStackMediaCollectionCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-14.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoverFlowStackCollectionViewLayout

final class CoverFlowStackMediaCollectionCell: UICollectionViewCell {
    
    private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(cell: self)
        return viewModel
    }()
    
    let mediaView = MediaView()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        mediaView.prepareForReuse()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension CoverFlowStackMediaCollectionCell {
    
    private func _init() {
        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = MediaView.cornerRadius
        contentView.layer.cornerCurve = .continuous
        
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mediaView)
        NSLayoutConstraint.activate([
            mediaView.topAnchor.constraint(equalTo: contentView.topAnchor),
            mediaView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mediaView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        // delegate user interactive to collection view
        mediaView.isUserInteractionEnabled = false
    }

}

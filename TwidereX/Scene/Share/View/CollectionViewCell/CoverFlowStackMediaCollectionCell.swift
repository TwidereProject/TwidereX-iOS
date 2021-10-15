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
    
    private var mediaViewWidthLayoutConstraint: NSLayoutConstraint!
    private var mediaViewHeightLayoutConstraint: NSLayoutConstraint!
    private var placeholderConstraints: [NSLayoutConstraint] = []
    
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
            mediaView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            mediaView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        
        placeholderConstraints =  [
            mediaView.topAnchor.constraint(equalTo: contentView.topAnchor).priority(.defaultHigh),
            mediaView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).priority(.defaultHigh),
            mediaView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).priority(.defaultHigh),
            mediaView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).priority(.defaultHigh),
        ]
        NSLayoutConstraint.activate(placeholderConstraints)
        
        mediaViewWidthLayoutConstraint = mediaView.widthAnchor.constraint(equalToConstant: 100)
        mediaViewHeightLayoutConstraint = mediaView.heightAnchor.constraint(equalToConstant: 100)
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        guard let attributes = layoutAttributes as? CoverFlowStackLayoutAttributes else { return }
        
        let size = attributes.originalFrame.size
        mediaViewWidthLayoutConstraint.constant = size.width
        mediaViewHeightLayoutConstraint.constant = size.height
        NSLayoutConstraint.activate([
            mediaViewWidthLayoutConstraint,
            mediaViewHeightLayoutConstraint,
        ])
        
        NSLayoutConstraint.deactivate(placeholderConstraints)
    }
    
}

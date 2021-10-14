//
//  StatusMediaGalleryCollectionCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-14.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine

final class StatusMediaGalleryCollectionCell: UICollectionViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(cell: self) 
        return viewModel
    }()

    let mediaView = MediaView()
        
    override func prepareForReuse() {
        super.prepareForReuse()
    
        disposeBag.removeAll()
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

extension StatusMediaGalleryCollectionCell {
    
    private func _init() {
        contentView.backgroundColor = .red
        
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mediaView)
        NSLayoutConstraint.activate([
            mediaView.topAnchor.constraint(equalTo: contentView.topAnchor),
            mediaView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mediaView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
}

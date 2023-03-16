//
//  StatusMediaGalleryCollectionCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-14.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine
import CoverFlowStackCollectionViewLayout

protocol StatusMediaGalleryCollectionCellDelegate: AnyObject {
    func statusMediaGalleryCollectionCell(_ cell: StatusMediaGalleryCollectionCell, coverFlowCollectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    func statusMediaGalleryCollectionCell(_ cell: StatusMediaGalleryCollectionCell, toggleContentWarningOverlayViewDisplay contentWarningOverlayView: ContentWarningOverlayView)
}

final class StatusMediaGalleryCollectionCell: UICollectionViewCell {
    
    let logger = Logger(subsystem: "StatusMediaGalleryCollectionCell", category: "Cell")
    
    weak var delegate: StatusMediaGalleryCollectionCellDelegate?
    
    var disposeBag = Set<AnyCancellable>()
    private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(cell: self)
        return viewModel
    }()
    
//    let sensitiveToggleButtonBlurVisualEffectView: UIVisualEffectView = {
//        let visualEffectView = UIVisualEffectView(effect: ContentWarningOverlayView.blurVisualEffect)
//        visualEffectView.layer.masksToBounds = true
//        visualEffectView.layer.cornerRadius = 6
//        visualEffectView.layer.cornerCurve = .continuous
//        return visualEffectView
//    }()
//    let sensitiveToggleButtonVibrancyVisualEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: ContentWarningOverlayView.blurVisualEffect))
    let sensitiveToggleButton: HitTestExpandedButton = {
        let button = HitTestExpandedButton(type: .system)
        button.setImage(Asset.Human.eyeSlashMini.image.withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()
    
//    public let contentWarningOverlayView: ContentWarningOverlayView = {
//        let overlay = ContentWarningOverlayView()
//        overlay.layer.masksToBounds = true
//        overlay.layer.cornerRadius = MediaView.cornerRadius
//        overlay.layer.cornerCurve = .continuous
//        return overlay
//    }()
    
//    let mediaView = MediaView()
    
    let collectionViewLayout: CoverFlowStackCollectionViewLayout = {
        let layout = CoverFlowStackCollectionViewLayout()
        layout.sizeScaleRatio = 0.9
        return layout
    }()
    private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = .clear
        collectionView.layer.masksToBounds = true
//        collectionView.layer.cornerRadius = MediaView.cornerRadius
        collectionView.layer.cornerCurve = .continuous
        return collectionView
    }()
    var diffableDataSource: UICollectionViewDiffableDataSource<CoverFlowStackSection, CoverFlowStackItem>?
        
    override func prepareForReuse() {
        super.prepareForReuse()
    
        disposeBag.removeAll()
//        mediaView.prepareForReuse()
        diffableDataSource?.applySnapshotUsingReloadData(.init())
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
//        mediaView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(mediaView)
//        NSLayoutConstraint.activate([
//            mediaView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            mediaView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            mediaView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            mediaView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//        ])
//        
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(collectionView)
//        NSLayoutConstraint.activate([
//            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//        ])
//        
//        // sensitiveToggleButton
//        sensitiveToggleButtonBlurVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(sensitiveToggleButtonBlurVisualEffectView)
//        NSLayoutConstraint.activate([
//            sensitiveToggleButtonBlurVisualEffectView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
//            sensitiveToggleButtonBlurVisualEffectView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
//        ])
//        
//        sensitiveToggleButtonVibrancyVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
//        sensitiveToggleButtonBlurVisualEffectView.contentView.addSubview(sensitiveToggleButtonVibrancyVisualEffectView)
//        NSLayoutConstraint.activate([
//            sensitiveToggleButtonVibrancyVisualEffectView.topAnchor.constraint(equalTo: sensitiveToggleButtonBlurVisualEffectView.contentView.topAnchor),
//            sensitiveToggleButtonVibrancyVisualEffectView.leadingAnchor.constraint(equalTo: sensitiveToggleButtonBlurVisualEffectView.contentView.leadingAnchor),
//            sensitiveToggleButtonVibrancyVisualEffectView.trailingAnchor.constraint(equalTo: sensitiveToggleButtonBlurVisualEffectView.contentView.trailingAnchor),
//            sensitiveToggleButtonVibrancyVisualEffectView.bottomAnchor.constraint(equalTo: sensitiveToggleButtonBlurVisualEffectView.contentView.bottomAnchor),
//        ])
//        
//        sensitiveToggleButton.translatesAutoresizingMaskIntoConstraints = false
//        sensitiveToggleButtonVibrancyVisualEffectView.contentView.addSubview(sensitiveToggleButton)
//        NSLayoutConstraint.activate([
//            sensitiveToggleButton.topAnchor.constraint(equalTo: sensitiveToggleButtonVibrancyVisualEffectView.contentView.topAnchor, constant: 4),
//            sensitiveToggleButton.leadingAnchor.constraint(equalTo: sensitiveToggleButtonVibrancyVisualEffectView.contentView.leadingAnchor, constant: 4),
//            sensitiveToggleButtonVibrancyVisualEffectView.contentView.trailingAnchor.constraint(equalTo: sensitiveToggleButton.trailingAnchor, constant: 4),
//            sensitiveToggleButtonVibrancyVisualEffectView.contentView.bottomAnchor.constraint(equalTo: sensitiveToggleButton.bottomAnchor, constant: 4),
//        ])
//        
//        // contentWarningOverlayView
//        contentWarningOverlayView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(contentWarningOverlayView)       // should add to container
//        NSLayoutConstraint.activate([
//            contentWarningOverlayView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            contentWarningOverlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            contentWarningOverlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            contentWarningOverlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//        ])
//        
//        // delegate interaction to collection view
//        mediaView.isUserInteractionEnabled = false
//
//        collectionView.delegate = self
//        let configuration = CoverFlowStackSection.Configuration()
//        diffableDataSource = CoverFlowStackSection.diffableDataSource(
//            collectionView: collectionView,
//            configuration: configuration
//        )
//        
//        sensitiveToggleButton.addTarget(self, action: #selector(StatusMediaGalleryCollectionCell.sensitiveToggleButtonDidPressed(_:)), for: .touchUpInside)
//        contentWarningOverlayView.delegate = self
    }
    
}

extension StatusMediaGalleryCollectionCell {
    @objc private func sensitiveToggleButtonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
//        delegate?.statusMediaGalleryCollectionCell(self, toggleContentWarningOverlayViewDisplay: contentWarningOverlayView)
    }
}

// MARK: - UICollectionViewDelegate
extension StatusMediaGalleryCollectionCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): did select \(indexPath.debugDescription)")
        delegate?.statusMediaGalleryCollectionCell(self, coverFlowCollectionView: collectionView, didSelectItemAt: indexPath)
    }
}

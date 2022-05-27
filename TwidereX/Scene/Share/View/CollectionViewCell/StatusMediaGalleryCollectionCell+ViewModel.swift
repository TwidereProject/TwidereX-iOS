//
//  StatusMediaGalleryCollectionCell+ViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-14.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreDataStack
import CoverFlowStackCollectionViewLayout

extension StatusMediaGalleryCollectionCell {
    final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()

        @Published var mediaViewConfigurations: [MediaView.Configuration] = []

        // input
        @Published public var isMediaSensitive: Bool = false
        @Published public var isMediaSensitiveToggled: Bool = false
        @Published public var isMediaSensitiveSwitchable = false

        // output
        @Published public var isMediaReveal: Bool = false
        @Published public var isSensitiveToggleButtonDisplay: Bool = false
        @Published public var isContentWarningOverlayDisplay: Bool? = nil
        
        init() {
            Publishers.CombineLatest(
                $isMediaSensitive,
                $isMediaSensitiveToggled
            )
            .map { $1 ? !$0 : $0 }
            .assign(to: &$isMediaReveal)
            $isMediaReveal
                .sink { [weak self] isMediaReveal in
                    guard let self = self else { return }
                    self.isContentWarningOverlayDisplay = isMediaReveal
                }
                .store(in: &disposeBag)
            $isMediaSensitiveSwitchable
                .sink { [weak self] isMediaSensitiveSwitchable in
                    guard let self = self else { return }
                    self.isSensitiveToggleButtonDisplay = isMediaSensitiveSwitchable
                }
                .store(in: &disposeBag)
        }
    }
}

extension StatusMediaGalleryCollectionCell.ViewModel {
    
    func resetContentWarningOverlay() {
        isContentWarningOverlayDisplay = nil
    }
    
    func bind(cell: StatusMediaGalleryCollectionCell) {
        $mediaViewConfigurations
            .sink { [weak self] configurations in
                guard let self = self else { return }
                
                switch configurations.count {
                case 0:
                    cell.mediaView.isHidden = true
                    cell.collectionView.isHidden = true
                case 1:
                    cell.mediaView.setup(configuration: configurations[0])
                    cell.mediaView.isHidden = false
                    cell.collectionView.isHidden = true
                default:
                    var snapshot = NSDiffableDataSourceSnapshot<CoverFlowStackSection, CoverFlowStackItem>()
                    snapshot.appendSections([.main])
                    let items: [CoverFlowStackItem] = configurations.map { .media(configuration: $0) }
                    snapshot.appendItems(items, toSection: .main)
                    cell.diffableDataSource?.applySnapshotUsingReloadData(snapshot)
                    cell.mediaView.isHidden = true
                    cell.collectionView.isHidden = false
                }
            }
            .store(in: &disposeBag)
        $isSensitiveToggleButtonDisplay
            .sink { isDisplay in
                cell.sensitiveToggleButtonBlurVisualEffectView.isHidden = !isDisplay
            }
            .store(in: &disposeBag)
        $isContentWarningOverlayDisplay
            .sink { isDisplay in
                assert(Thread.isMainThread)
                
                let isDisplay = isDisplay ?? false
                let withAnimation = self.isContentWarningOverlayDisplay != nil
                
                if withAnimation {
                    UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseInOut) {
                        cell.contentWarningOverlayView.blurVisualEffectView.alpha = isDisplay ? 1 : 0
                    }
                } else {
                    cell.contentWarningOverlayView.blurVisualEffectView.alpha = isDisplay ? 1 : 0
                }
                
                cell.contentWarningOverlayView.isUserInteractionEnabled = isDisplay
                cell.contentWarningOverlayView.tapGestureRecognizer.isEnabled = isDisplay
            }
            .store(in: &disposeBag)
    }
}


extension StatusMediaGalleryCollectionCell {
    func configure(status object: StatusObject) {
        switch object {
        case .twitter(let status):
            configure(twitterStatus: status)
        case .mastodon(let status):
            configure(mastodonStatus: status)
        }
    }

    private func configure(twitterStatus status: TwitterStatus) {
        let status = status.repost ?? status

        viewModel.resetContentWarningOverlay()
        viewModel.isMediaSensitive = false
        viewModel.isMediaSensitiveToggled = false
        viewModel.isMediaSensitiveSwitchable = false
        viewModel.mediaViewConfigurations = MediaView.configuration(twitterStatus: status)
    }
    
    private func configure(mastodonStatus status: MastodonStatus) {
        let status = status.repost ?? status

        viewModel.resetContentWarningOverlay()
        viewModel.isMediaSensitiveSwitchable = true
        viewModel.mediaViewConfigurations = MediaView.configuration(mastodonStatus: status)
        status.publisher(for: \.isMediaSensitive)
            .receive(on: DispatchQueue.main)
            .assign(to: \.isMediaSensitive, on: viewModel)
            .store(in: &disposeBag)
        status.publisher(for: \.isMediaSensitiveToggled)
            .receive(on: DispatchQueue.main)
            .assign(to: \.isMediaSensitiveToggled, on: viewModel)
            .store(in: &disposeBag)
    }
}

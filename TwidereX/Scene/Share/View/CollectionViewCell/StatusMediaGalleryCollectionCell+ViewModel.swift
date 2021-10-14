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

extension StatusMediaGalleryCollectionCell {
    final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()

        @Published var mediaViewConfigurations: [MediaView.Configuration] = []
    }
}

extension StatusMediaGalleryCollectionCell.ViewModel {
    func bind(cell: StatusMediaGalleryCollectionCell) {
        $mediaViewConfigurations
            .sink { configurations in
                if let first = configurations.first {
                    cell.mediaView.setup(configuration: first)
                }
            }
            .store(in: &disposeBag)
    }
}


extension StatusMediaGalleryCollectionCell {
    func configure(status: StatusObject) {
        switch status {
        case .twitter(let object):
            configure(twitterStatus: object)
        case .mastodon(let object):
            break
        }
    }

    private func configure(twitterStatus status: TwitterStatus) {
        MediaView.configuration(twitterStatus: status)
            .assign(to: \.mediaViewConfigurations, on: viewModel)
            .store(in: &disposeBag)
    }
}

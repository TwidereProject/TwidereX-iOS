//
//  TimelineMiddleLoaderTableViewCell+ViewModel.swift
//  TimelineMiddleLoaderTableViewCell+ViewModel
//
//  Created by Cirno MainasuK on 2021-9-2.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import SwiftUI
import CoreDataStack

extension TimelineMiddleLoaderTableViewCell {
    public class ViewModel {
        var disposeBag = Set<AnyCancellable>()

        @Published public var isFetching = false
    }
    
    func configure(
        feed: Feed,
        delegate: TimelineMiddleLoaderTableViewCellDelegate?
    ) {
        feed.publisher(for: \.isLoadingMore)
            .sink { [weak self] isLoadingMore in
                guard let self = self else { return }
                self.viewModel.isFetching = isLoadingMore
            }
            .store(in: &disposeBag)
        
        self.delegate = delegate
    }
}

extension TimelineMiddleLoaderTableViewCell.ViewModel {
    func bind(cell: TimelineMiddleLoaderTableViewCell) {
        $isFetching
            .sink { isFetching in
                cell.loadMoreButton.isHidden = isFetching
                if isFetching {
                    cell.activityIndicatorView.startAnimating()
                } else {
                    cell.activityIndicatorView.stopAnimating()
                }
            }
            .store(in: &disposeBag)
    }
}

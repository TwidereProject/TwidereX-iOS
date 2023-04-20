//
//  CoverFlowStackMediaCollectionCell+ViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-10-14.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine
import CoreDataStack

extension CoverFlowStackMediaCollectionCell {
    final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        
        @Published var mediaViewModel: MediaView.ViewModel?
    }
}

extension CoverFlowStackMediaCollectionCell.ViewModel {
    func bind(cell: CoverFlowStackMediaCollectionCell) {
//        $mediaViewConfiguration
//            .sink { configuration in
//                guard let configuration = configuration else { return }
//                cell.mediaView.setup(configuration: configuration)
//            }
//            .store(in: &disposeBag)
    }
}


extension CoverFlowStackMediaCollectionCell {
    func configure(configuration: MediaView.ViewModel) {
//        viewModel.mediaViewConfiguration = configuration
    }
}

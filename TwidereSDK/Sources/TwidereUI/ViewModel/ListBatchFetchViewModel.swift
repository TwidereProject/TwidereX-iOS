//
//  ListBatchFetchViewModel.swift
//  ListBatchFetchViewModel
//
//  Created by Cirno MainasuK on 2021-9-1.
//  Copyright © 2021 Twidere. All rights reserved.
//

import os.log
import Foundation
import Combine
import UIKit

// ref: Texture.ASBatchFetchingDelegate
public final class ListBatchFetchViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // timer running on `common` mode
    let timerPublisher = Timer.publish(every: 1.0, on: .main, in: .common)
        .autoconnect()
        .share()
        .eraseToAnyPublisher()
    
    // input
    private(set) weak var scrollView: UIScrollView?
    let hasMore = CurrentValueSubject<Bool, Never>(true)
    
    // output
    public let shouldFetch = PassthroughSubject<Void, Never>()
    
    public init(direction: Direction = .bottom) {
        Publishers.CombineLatest(
            hasMore,
            timerPublisher
        )
        .sink { [weak self] hasMore, _ in
            guard let self = self else { return }
            guard hasMore else { return }
            guard let scrollView = self.scrollView else { return }

            // skip trigger if user interacting
            if scrollView.isDragging || scrollView.isTracking { return }

            // send fetch request
            if scrollView.contentSize.height < scrollView.frame.height {
                self.shouldFetch.send()
            } else {
                let frame = scrollView.frame
                let contentOffset = scrollView.contentOffset
                let contentSize = scrollView.contentSize
                
                switch direction {
                case .top:
                    if contentOffset.y < frame.height / 2 {
                        self.shouldFetch.send()
                    }
                case .bottom:
                    let visibleBottomY = contentOffset.y + frame.height
                    let offset = 2 * frame.height
                    let fetchThrottleOffsetY = contentSize.height - offset
                    
                    if visibleBottomY > fetchThrottleOffsetY {
                        self.shouldFetch.send()
                    }
                }
            }
        }
        .store(in: &disposeBag)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension ListBatchFetchViewModel {
    public enum Direction {
        case top
        case bottom
    }
    
}

extension ListBatchFetchViewModel {
    public func setup(scrollView: UIScrollView) {
        self.scrollView = scrollView
    }
}

//
//  MediaGridContainerView+ViewModel.swift
//  
//
//  Created by MainasuK on 2021-12-14.
//

import UIKit
import Combine

extension MediaGridContainerView {
    public class ViewModel {
        var disposeBag = Set<AnyCancellable>()
        @Published public var isSensitiveToggleButtonDisplay: Bool = false
        @Published public var isContentWarningOverlayDisplay: Bool? = nil
    }
}

extension MediaGridContainerView.ViewModel {
    
    func resetContentWarningOverlay() {
        isContentWarningOverlayDisplay = nil
    }
    
    func bind(view: MediaGridContainerView) {
        $isSensitiveToggleButtonDisplay
            .sink { isDisplay in
                view.sensitiveToggleButtonBlurVisualEffectView.isHidden = !isDisplay
            }
            .store(in: &disposeBag)
        $isContentWarningOverlayDisplay
            .receive(on: DispatchQueue.main)
            .sink { isDisplay in
                let isDisplay = isDisplay ?? false
                
                let withAnimation = self.isContentWarningOverlayDisplay != nil
                if withAnimation {
                    UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseInOut) {
                        view.contentWarningOverlayView.blurVisualEffectView.alpha = isDisplay ? 1 : 0
                    }
                } else {
                    view.contentWarningOverlayView.blurVisualEffectView.alpha = isDisplay ? 1 : 0
                }
                
                view.contentWarningOverlayView.isUserInteractionEnabled = isDisplay
                view.contentWarningOverlayView.tapGestureRecognizer.isEnabled = isDisplay
            }
            .store(in: &disposeBag)
    }
    
}

//
//  KeyboardResponderService.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-8-14.
//  Copyright © 2020 Dimension. All rights reserved.
//

import UIKit
import Combine

final class KeyboardResponderService {
    
    var disposeBag = Set<AnyCancellable>()
    
    // MARK: - Singleton
    public static let shared = KeyboardResponderService()
    
    // output
    let isShow = CurrentValueSubject<Bool, Never>(false)
    let state = CurrentValueSubject<KeyboardState, Never>(.none)
    let endFrame = CurrentValueSubject<CGRect, Never>(.zero)
    
    private init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification, object: nil)
            .sink { notification in
                self.isShow.value = true
                self.updateInternalStatus(notification: notification)
            }
            .store(in: &disposeBag)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification, object: nil)
            .sink { notification in
                self.isShow.value = false
                self.updateInternalStatus(notification: notification)
            }
            .store(in: &disposeBag)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardDidChangeFrameNotification, object: nil)
            .sink { notification in
                self.updateInternalStatus(notification: notification)
            }
            .store(in: &disposeBag)
    }
    
}

extension KeyboardResponderService {
    
    private func updateInternalStatus(notification: Notification) {
        guard let isLocal = notification.userInfo?[UIWindow.keyboardIsLocalUserInfoKey] as? Bool,
            let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
        }
        
        self.endFrame.value = endFrame
        
        guard isLocal else {
            self.state.value = .notLocal
            return
        }
        
        // check if floating
        guard endFrame.width == UIScreen.main.bounds.width else {
            self.state.value = .floating
            return
        }
        
        // check if undock | split
        let dockMinY = UIScreen.main.bounds.height - endFrame.height
        if endFrame.minY < dockMinY {
            self.state.value = .notDock
        } else {
            self.state.value = .dock
        }
    }
    
}

extension KeyboardResponderService {
    enum KeyboardState {
        case none
        case notLocal
        case notDock        // undock | split
        case floating       // iPhone size floating
        case dock
    }
}

extension KeyboardResponderService {
    static func configure(
        scrollView: UIScrollView,
        viewDidAppear: AnyPublisher<Void, Never>
    ) -> AnyCancellable {
        return Publishers.CombineLatest4(
            KeyboardResponderService.shared.isShow,
            KeyboardResponderService.shared.state,
            KeyboardResponderService.shared.endFrame,
            viewDidAppear       // make sure trigger again when view available
        )
        .sink(receiveValue: { [weak scrollView] isShow, state, endFrame, _ in
            guard let scrollView = scrollView else { return }
            guard let view = scrollView.superview else { return }
            
            guard isShow, state == .dock else {
                scrollView.contentInset.bottom = 0.0
                scrollView.verticalScrollIndicatorInsets.bottom = 0.0
                return
            }
            
            // isShow AND dock state
            let contentFrame = view.convert(scrollView.frame, to: nil)
            let padding = contentFrame.maxY - endFrame.minY
            guard padding > 0 else {
                scrollView.contentInset.bottom = 0.0
                scrollView.verticalScrollIndicatorInsets.bottom = 0.0
                return
            }
            
            scrollView.contentInset.bottom = padding - scrollView.safeAreaInsets.bottom
            scrollView.verticalScrollIndicatorInsets.bottom = padding - scrollView.safeAreaInsets.bottom
        })
    }
}

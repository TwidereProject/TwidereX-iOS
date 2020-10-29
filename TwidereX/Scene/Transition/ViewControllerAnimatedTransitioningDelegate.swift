//
//  ViewControllerAnimatedTransitioningDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 12/21/18.
//

import Foundation

protocol ViewControllerAnimatedTransitioningDelegate: class {
    var wantsInteractiveStart: Bool { get }
    func animationEnded(_ transitionCompleted: Bool)
}

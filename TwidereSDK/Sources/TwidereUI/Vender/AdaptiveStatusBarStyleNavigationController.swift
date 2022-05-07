//
//  AdaptiveStatusBarStyleNavigationController.swift
//
//
//  Created by MainasuK Cirno on 2021-2-26.
//

import UIKit

// Make status bar style adaptive for child view controller
// SeeAlso: `modalPresentationCapturesStatusBarAppearance`
public class AdaptiveStatusBarStyleNavigationController: UINavigationController {

    private lazy var fullWidthBackGestureRecognizer = UIPanGestureRecognizer()

    public override var childForStatusBarStyle: UIViewController? {
        visibleViewController
    }
}

// ref: https://stackoverflow.com/a/60598558/3797903
extension AdaptiveStatusBarStyleNavigationController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupFullWidthBackGesture()
    }

    private func setupFullWidthBackGesture() {
        // The trick here is to wire up our full-width `fullWidthBackGestureRecognizer` to execute the same handler as
        // the system `interactivePopGestureRecognizer`. That's done by assigning the same "targets" (effectively
        // object and selector) of the system one to our gesture recognizer.
        guard let interactivePopGestureRecognizer = interactivePopGestureRecognizer,
              let targets = interactivePopGestureRecognizer.value(forKey: "targets")
        else { return }

        fullWidthBackGestureRecognizer.setValue(targets, forKey: "targets")
        fullWidthBackGestureRecognizer.delegate = self
        view.addGestureRecognizer(fullWidthBackGestureRecognizer)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension AdaptiveStatusBarStyleNavigationController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let isSystemSwipeToBackEnabled = interactivePopGestureRecognizer?.isEnabled == true
        let isThereStackedViewControllers = viewControllers.count > 1
        return isSystemSwipeToBackEnabled && isThereStackedViewControllers
    }
}

//
//  ScrollViewContainer.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-8.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

protocol ScrollViewContainer: UIViewController {
    var scrollView: UIScrollView { get }
    func scrollToTop(animated: Bool, option: ScrollViewContainerOption)
}

extension ScrollViewContainer {
    func scrollToTop(animated: Bool, option: ScrollViewContainerOption = .init()) {
        scrollView.scrollRectToVisible(
            CGRect(origin: .zero, size: CGSize(width: 1, height: 1)),
            animated: animated
        )
    }
}

struct ScrollViewContainerOption {
    let tryRefreshWhenStayAtTop: Bool
    
    init(tryRefreshWhenStayAtTop: Bool = true) {
        self.tryRefreshWhenStayAtTop = tryRefreshWhenStayAtTop
    }
}

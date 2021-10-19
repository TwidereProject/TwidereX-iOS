//
//  TabBarPagerHeader.swift
//
//
//  Created by Cirno MainasuK on 2021-10-13.
//

import UIKit

public protocol TabBarPagerHeaderDelegate: AnyObject {
    func viewLayoutDidUpdate(_ header: TabBarPagerHeader)
}

public protocol TabBarPagerHeader: AnyObject {
    var headerDelegate: TabBarPagerHeaderDelegate? { get set }
}

//
//  TabBarPagerDelegate.swift
//  
//
//  Created by Cirno MainasuK on 2021-10-15.
//

import UIKit

public protocol TabBarPagerDelegate: AnyObject {
    func tabBarMinimalHeight() -> CGFloat
    func resetPageContentOffset(_ tabBarPagerController: TabBarPagerController)
    func tabBarPagerController(_ tabBarPagerController: TabBarPagerController, didScroll scrollView: UIScrollView)
}

//
//  UIViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-10-21.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

extension UIViewController {
    /// https://bluelemonbits.com/2018/08/26/inserting-cells-at-the-top-of-a-uitableview-with-no-scrolling/
    static func topVisibleTableViewCellIndexPath(in tableView: UITableView, navigationBar: UINavigationBar) -> IndexPath? {
        let navigationBarRectInTableView = tableView.convert(navigationBar.bounds, from: navigationBar)
        let navigationBarMaxYPosition = CGPoint(x: 0, y: navigationBarRectInTableView.origin.y + navigationBarRectInTableView.size.height + 1)
        let mostTopVisiableIndexPath = tableView.indexPathForRow(at: navigationBarMaxYPosition)
        return mostTopVisiableIndexPath
    }
    
    static func tableViewCellOriginOffsetToWindowTop(in tableView: UITableView, at indexPath: IndexPath, navigationBar: UINavigationBar) -> CGFloat {
        let rectForTopRow = tableView.rectForRow(at: indexPath)
        let navigationBarRectInTableView = tableView.convert(navigationBar.bounds, from: navigationBar)
        let navigationBarMaxYPosition = CGPoint(x: 0, y: navigationBarRectInTableView.origin.y + navigationBarRectInTableView.size.height + 1)
        let differenceBetweenTopRowAndNavigationBar = rectForTopRow.origin.y - navigationBarMaxYPosition.y
        return differenceBetweenTopRowAndNavigationBar
    }
}

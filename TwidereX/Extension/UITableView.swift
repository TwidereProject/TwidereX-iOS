//
//  UITableView.swift
//  Cebu
//
//  Created by Cirno MainasuK on 2020-8-13.
//  Copyright © 2020 Dimension. All rights reserved.
//

import UIKit

extension UITableView {
    
    static let groupedTableViewPaddingHeaderViewHeight: CGFloat = 16
    static var groupedTableViewPaddingHeaderView: UIView {
        return UIView(frame: CGRect(x: 0, y: 0, width: 100, height: groupedTableViewPaddingHeaderViewHeight))
    }
    
}

extension UITableView {
    
    func deselectRow(with transitionCoordinator: UIViewControllerTransitionCoordinator?, animated: Bool) {
        guard let indexPathForSelectedRow = indexPathForSelectedRow else { return }
        
        guard let transitionCoordinator = transitionCoordinator else {
            deselectRow(at: indexPathForSelectedRow, animated: animated)
            return
        }
        
        transitionCoordinator.animate(alongsideTransition: { _ in
            self.deselectRow(at: indexPathForSelectedRow, animated: animated)
        }, completion: { context in
            if context.isCancelled {
                self.selectRow(at: indexPathForSelectedRow, animated: animated, scrollPosition: .none)
            }
        })
    }
    
    func blinkRow(at indexPath: IndexPath) {
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            guard let cell = self.cellForRow(at: indexPath) else { return }
            let backgroundColor = cell.backgroundColor
            
            UIView.animate(withDuration: 0.3) {
                cell.backgroundColor = Asset.Colors.hightLight.color.withAlphaComponent(0.5)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIView.animate(withDuration: 0.3) {
                        cell.backgroundColor = backgroundColor
                    }
                }
            }
        }
    }
    
}

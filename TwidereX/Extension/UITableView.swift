//
//  UITableView.swift
//  Cebu
//
//  Created by Cirno MainasuK on 2020-8-13.
//  Copyright © 2020 Dimension. All rights reserved.
//

import UIKit

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
    
}

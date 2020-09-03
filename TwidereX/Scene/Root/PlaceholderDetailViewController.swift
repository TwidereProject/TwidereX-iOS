//
//  PlaceholderDetailViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-8-10.
//  Copyright © 2020 Dimension. All rights reserved.
//

import UIKit

final class PlaceholderDetailViewController: UIViewController {
    
    let promptLabel: UILabel = {
        let label = UILabel()
        label.text = "No Selection"
        label.textColor = .secondaryLabel
        return label
    }()
    
}

extension PlaceholderDetailViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(promptLabel)
        NSLayoutConstraint.activate([
            promptLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            promptLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
}

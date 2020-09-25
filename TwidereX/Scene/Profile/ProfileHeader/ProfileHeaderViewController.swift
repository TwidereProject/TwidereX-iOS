//
//  ProfileHeaderViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-24.
//

import UIKit

protocol ProfileHeaderViewControllerDelegate: class {
    func profileHeaderViewController(_ viewController: ProfileHeaderViewController, viewLayoutDidUpdate view: UIView)
}

final class ProfileHeaderViewController: UIViewController {
    
    static let headerMinHeight: CGFloat = 50
    
    weak var delegate: ProfileHeaderViewControllerDelegate?
    
    let expandButton: UIButton = {
        let button = UIButton()
        button.setTitle("Update header height", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.setTitleColor(UIColor.systemBlue.withAlphaComponent(0.5), for: .highlighted)
        return button
    }()
    var headerHeight: CGFloat = 100
    var expandButtonHeightLayoutConstraint: NSLayoutConstraint!
}

extension ProfileHeaderViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        expandButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(expandButton)
        expandButtonHeightLayoutConstraint = expandButton.heightAnchor.constraint(equalToConstant: headerHeight).priority(.defaultHigh)
        NSLayoutConstraint.activate([
            expandButton.topAnchor.constraint(equalTo: view.topAnchor),
            expandButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            expandButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: expandButton.bottomAnchor, constant: ProfileHeaderViewController.headerMinHeight),
            expandButtonHeightLayoutConstraint
        ])
        expandButton.addTarget(self, action: #selector(ProfileHeaderViewController.expandButtonPressed(_:)), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        delegate?.profileHeaderViewController(self, viewLayoutDidUpdate: view)
    }
    
}

extension ProfileHeaderViewController {
    @objc private func expandButtonPressed(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3) {
            self.headerHeight = self.headerHeight > 300 ? 100 : self.headerHeight + 50
            self.expandButtonHeightLayoutConstraint.constant = self.headerHeight
            
        }
    }
}

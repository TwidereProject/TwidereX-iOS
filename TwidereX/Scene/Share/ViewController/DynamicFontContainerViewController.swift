//
//  DynamicFontContainerViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-19.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import Combine

final class DynamicFontContainerViewController: UIViewController {
    
    var disposeBag = Set<AnyCancellable>()
    
    var child: UIViewController!
}

extension DynamicFontContainerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view)
        NSLayoutConstraint.activate([
            child.view.topAnchor.constraint(equalTo: view.topAnchor),
            child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        Publishers.CombineLatest(
            UserDefaults.shared.publisher(for: \.useTheSystemFontSize).eraseToAnyPublisher(),
            UserDefaults.shared.publisher(for: \.customContentSizeCatagory)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] useTheSystemFontSize, customContentSizeCatagory in
            guard let self = self else { return }
            let traitCollection = useTheSystemFontSize ? UITraitCollection(preferredContentSizeCategory: UIApplication.shared.preferredContentSizeCategory) : UITraitCollection(preferredContentSizeCategory: customContentSizeCatagory)
            self.setOverrideTraitCollection(traitCollection, forChild: self.child)
        }
        .store(in: &disposeBag)
    }
    
}


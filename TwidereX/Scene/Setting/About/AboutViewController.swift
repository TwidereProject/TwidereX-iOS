//
//  AboutViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-12.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import SwiftUI
import Combine
import SafariServices

final class AboutViewController: UIViewController, NeedsDependency {

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    let aboutView = AboutView()
    
}

extension AboutViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "About"
        
        let hostingViewController = UIHostingController(rootView: aboutView.environmentObject(context))
        addChild(hostingViewController)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingViewController.view)
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        context.viewStateStore.aboutView.aboutEntryPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entry in
                guard let self = self else { return }
                
                switch entry {
                case .github:
                    let url = URL(string: "https://github.com/TwidereProject/TwidereX-iOS")!
//                    self.definesPresentationContext = true
                    self.coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
                case .twitter:
                    let url = URL(string: "https://twitter.com/TwidereProject")!
//                    self.definesPresentationContext = true
                    self.coordinator.present(scene: .safari(url: url), from: self, transition: .safariPresent(animated: true, completion: nil))
                }
            }
            .store(in: &disposeBag)
    }
    
}

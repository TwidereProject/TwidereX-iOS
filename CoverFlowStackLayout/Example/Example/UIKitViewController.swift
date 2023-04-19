//
//  UIKitViewController.swift
//  Example
//
//  Created by Cirno MainasuK on 2021-10-15.
//

import UIKit
import CoverFlowStackCollectionViewLayout

class UIKitViewController: UIViewController {
    
    var colors: [UIColor] = (0..<20).map { i in
        return [.systemRed, .systemGreen, .systemBlue][i % 3]
    }
    
    let collectionViewLayout = CoverFlowStackCollectionViewLayout()
    private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.register(CollectionViewCell.self, forCellWithReuseIdentifier: String(describing: CollectionViewCell.self))
        
        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        title = "UIKit"
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.heightAnchor.constraint(equalTo: collectionView.widthAnchor),
        ])
        
        collectionView.dataSource = self
    }


}

final class CollectionViewCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension CollectionViewCell {
    
    private func _init() {
        
    }
    
}

// MARK: - UICollectionViewDataSource
extension UIKitViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: CollectionViewCell.self), for: indexPath) as! CollectionViewCell
        cell.backgroundColor = colors[indexPath.row]
        return cell
    }
}


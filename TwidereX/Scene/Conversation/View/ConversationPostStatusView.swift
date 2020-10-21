//
//  ConversationPostStatusView.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-18.
//

import UIKit

final class ConversationPostStatusView: UIView {
    
    let countLabel: UILabel = {
        let label = UILabel()
        label.text = "1"
        label.textAlignment = .right
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Retweet"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ConversationPostStatusView {
    private func _init() {
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countLabel)
        NSLayoutConstraint.activate([
            countLabel.topAnchor.constraint(equalTo: topAnchor),
            countLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomAnchor.constraint(equalTo: countLabel.bottomAnchor),
        ])
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: topAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: countLabel.trailingAnchor, constant: 4),
            trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor),
            bottomAnchor.constraint(equalTo: statusLabel.bottomAnchor),
        ])
        
        countLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
}


#if DEBUG
import SwiftUI

struct ConversationPostStatusView_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview(width: 300) {
            ConversationPostStatusView()
        }
        .previewLayout(.fixed(width: 300, height: 40))
    }
}
#endif

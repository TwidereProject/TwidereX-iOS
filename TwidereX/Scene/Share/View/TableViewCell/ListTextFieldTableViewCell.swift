//
//  ListTextFieldTableViewCell.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2021-1-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import Combine

final class ListTextFieldTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let textField = UITextField()
    let input = PassthroughSubject<String, Never>()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ListTextFieldTableViewCell {
    
    private func _init() {
        selectionStyle = .none
    
        textField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: contentView.topAnchor),
            textField.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor, constant: 4),   // visual alignment
            textField.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: textField.bottomAnchor),
            textField.heightAnchor.constraint(equalToConstant: 44).priority(.defaultHigh),
        ])
        
        NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: textField)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let text = self.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                self.input.send(text)
            }
            .store(in: &disposeBag)
    }
    
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ListTextFieldTableViewCell_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview {
            let cell = ListTextFieldTableViewCell()
            cell.textField.placeholder = "Placeholder"
            return cell
        }
        .previewLayout(.fixed(width: 500, height: 100))
    }
    
}

#endif


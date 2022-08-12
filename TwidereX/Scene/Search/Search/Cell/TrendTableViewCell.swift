//
//  TrendTableViewCell.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-28.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit
import MetaTextKit
import MetaLabel
import TwidereCore

final class TrendTableViewCell: UITableViewCell {
    
    let container: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        return stackView
    }()
    
    let infoContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    
    let lineChartContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    
    let primaryLabel = MetaLabel(style: .searchTrendTitle)
    let secondaryLabel = PlainLabel(style: .searchTrendSubtitle)
    let supplementaryLabel = PlainLabel(style: .searchTrendCount)
    let lineChartView = LineChartView()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        accessoryType = .none
        resetDisplay()
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

extension TrendTableViewCell {
    
    private func _init() {
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
            container.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 11),
        ])

        // container: H - [ info container | padding | supplementary | line chart container ]
        container.addArrangedSubview(infoContainer)
        
        // info container: V - [ primary | secondary ]
        infoContainer.addArrangedSubview(primaryLabel)
        infoContainer.addArrangedSubview(secondaryLabel)
        
        // padding
        let padding = UIView()
        container.addArrangedSubview(padding)
        
        // supplementary
        container.addArrangedSubview(supplementaryLabel)
        supplementaryLabel.setContentHuggingPriority(.required - 1, for: .horizontal)
        
        // line chart
        container.addArrangedSubview(lineChartContainer)
        
        let lineChartViewTopPadding = UIView()
        let lineChartViewBottomPadding = UIView()
        lineChartViewTopPadding.translatesAutoresizingMaskIntoConstraints = false
        lineChartViewBottomPadding.translatesAutoresizingMaskIntoConstraints = false
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        lineChartContainer.addArrangedSubview(lineChartViewTopPadding)
        lineChartContainer.addArrangedSubview(lineChartView)
        lineChartContainer.addArrangedSubview(lineChartViewBottomPadding)
        NSLayoutConstraint.activate([
            lineChartView.widthAnchor.constraint(equalToConstant: 66),
            lineChartView.heightAnchor.constraint(equalToConstant: 27),
            lineChartViewTopPadding.heightAnchor.constraint(equalTo: lineChartViewBottomPadding.heightAnchor),
        ])
        
        primaryLabel.isUserInteractionEnabled = false
        
        resetDisplay()
    }
    
}

extension TrendTableViewCell {
    
    func resetDisplay() {
        secondaryLabel.isHidden = true
        supplementaryLabel.isHidden = true
        lineChartContainer.isHidden = true
    }

    func setSecondaryLabelDisplay() {
        secondaryLabel.isHidden = false
    }
    
    func setSupplementaryLabelDisplay() {
        supplementaryLabel.isHidden = false
    }
    
    func setLineChartViewDisplay() {
        lineChartContainer.isHidden = false
    }
    
}

//
//  DisplayPreferenceViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-17.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

final class DisplayPreferenceViewController: UIViewController, NeedsDependency {

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var disposeBag = Set<AnyCancellable>()
    let viewModel = DisplayPreferenceViewModel()

    private(set) lazy var tableView: UITableView = {
        let tableView = ControlContainableTableView(frame: .zero, style: .grouped)
        tableView.register(TimelinePostTableViewCell.self, forCellReuseIdentifier: String(describing: TimelinePostTableViewCell.self))
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: String(describing: SwitchTableViewCell.self))
        tableView.register(SlideTableViewCell.self, forCellReuseIdentifier: String(describing: SlideTableViewCell.self))
        tableView.register(ListEntryTableViewCell.self, forCellReuseIdentifier: String(describing: ListEntryTableViewCell.self))
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 16))
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()
    
    let textFontSizeSliderPanGestureRecognizer = UIPanGestureRecognizer()
        
}

extension DisplayPreferenceViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Settings.Display.title
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = viewModel
        
        tableView.addGestureRecognizer(textFontSizeSliderPanGestureRecognizer)
        textFontSizeSliderPanGestureRecognizer.addTarget(self, action: #selector(DisplayPreferenceViewController.sliderPanGestureRecoginzerHandler(_:)))
        textFontSizeSliderPanGestureRecognizer.delegate = self
    }
    
}

// MARK: - UITableViewDelegate
extension DisplayPreferenceViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionData = viewModel.sections[section]
        let header = sectionData.header
        let headerView = TableViewSectionTextHeaderView()
        headerView.headerLabel.text = header
        return headerView
    }
    
}

extension DisplayPreferenceViewController {
    
    @objc private func sliderPanGestureRecoginzerHandler(_ sender: UIPanGestureRecognizer) {
        let slider = viewModel.fontSizeSlideTableViewCell.slider
        guard slider.isUserInteractionEnabled else { return }
        
        let position = sender.location(in: slider)
        let x = position.x
        let width = slider.bounds.width
        let progress = x / width
        let value = Float(progress) * slider.maximumValue + slider.minimumValue
        let roundValue = round(value)
        viewModel.fontSizeSlideTableViewCell.slider.setValue(roundValue, animated: true)

        let index = max(0, min(UserDefaults.contentSizeCategory.count - 1, Int(roundValue)))
        let customContentSizeCatagory = UserDefaults.contentSizeCategory[index]
        viewModel.customContentSizeCatagory.value = customContentSizeCatagory
    }
    
}

// MARK: - UIGestureRecognizerDelegate
extension DisplayPreferenceViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === textFontSizeSliderPanGestureRecognizer {
            return true
        }
        
        return false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === textFontSizeSliderPanGestureRecognizer {
            let slider = viewModel.fontSizeSlideTableViewCell.slider
            let position = gestureRecognizer.location(in: slider)
            guard position.x > 0 && position.x < slider.bounds.width else { return false }
            guard position.y > 0 && position.y < slider.bounds.height else  { return false }
            return true
        }
        
        return true
    }

}

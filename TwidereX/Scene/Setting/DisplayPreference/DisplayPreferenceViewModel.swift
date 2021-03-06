//
//  DisplayPreferenceViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-19.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit
import Combine

final class DisplayPreferenceViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let customContentSizeCatagory: CurrentValueSubject<UIContentSizeCategory, Never>
    
    // output
    let sections: [Section] = [
        Section(header: L10n.Scene.Settings.Display.SectionHeader.preview, settings: [.preview]),
        // Section(header: L10n.Scene.Settings.Display.SectionHeader.text, settings: [
        //     .useTheSystemFontSizeSwitch,
        //     .fontSizeSlider,
        // ]),
        Section(header: L10n.Scene.Settings.Display.Text.avatarStyle, settings: [
            .avatarStyle(.circle),
            .avatarStyle(.roundedSquare),
        ]),
    ]
    let fontSizeSlideTableViewCell = SlideTableViewCell()
    
    override init() {
        customContentSizeCatagory = CurrentValueSubject(UserDefaults.shared.customContentSizeCatagory)
        super.init()
        
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        customContentSizeCatagory
            .dropFirst()
            .removeDuplicates()
            .sink { customContentSizeCatagory in
                feedbackGenerator.impactOccurred()
                UserDefaults.shared.customContentSizeCatagory = customContentSizeCatagory
            }
            .store(in: &disposeBag)
    }
    
    
}

extension DisplayPreferenceViewModel {
    
    enum Setting {
        case preview
        
        case useTheSystemFontSizeSwitch
        case fontSizeSlider
        
        // Avatar Style
        case avatarStyle(UserDefaults.AvatarStyle)
            
        case dateFormat
    }
    
    struct Section {
        let header: String
        let settings: [Setting]
    }
    
}

// MARK: - UITableViewDataSource
extension DisplayPreferenceViewModel: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        let section = sections[indexPath.section]
        switch section.settings[indexPath.row] {
        case .preview:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelinePostTableViewCell.self), for: indexPath) as! TimelinePostTableViewCell
            DisplayPreferenceViewModel.configure(cell: _cell)
            cell = _cell
        case .useTheSystemFontSizeSwitch:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SwitchTableViewCell.self), for: indexPath) as! SwitchTableViewCell
            _cell.textLabel?.text = L10n.Scene.Settings.Display.Text.useTheSystemFontSize
            UserDefaults.shared.publisher(for: \.useTheSystemFontSize)
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { useTheSystemFontSize in
                    guard _cell.switcher.isOn != useTheSystemFontSize else { return }
                    _cell.switcher.setOn(useTheSystemFontSize, animated: true)
                })
                .store(in: &_cell.disposeBag)
            _cell.switcherPublisher
                .removeDuplicates()
                .assign(to: \.useTheSystemFontSize, on: UserDefaults.shared)
                .store(in: &_cell.disposeBag)
            cell = _cell
        case .fontSizeSlider:
            let _cell = fontSizeSlideTableViewCell      // prevent dequeue new cell instance
            _cell.disposeBag.removeAll()
            DisplayPreferenceViewModel.configureFontSizeSlider(cell: _cell)
            cell = _cell
        case .avatarStyle(let avatarStyle):
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ListCheckmarkTableViewCell.self), for: indexPath) as! ListCheckmarkTableViewCell
            _cell.titleLabel.text = avatarStyle.text
            UserDefaults.shared
                .observe(\.avatarStyle, options: [.initial, .new]) { defaults, _ in
                    _cell.accessoryType = avatarStyle == defaults.avatarStyle ? .checkmark : .none
                }
                .store(in: &_cell.observations)
            cell = _cell
        case .dateFormat:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ListEntryTableViewCell.self), for: indexPath) as! ListEntryTableViewCell
            _cell.iconImageView.isHidden = true
            _cell.titleLabel.text = L10n.Scene.Settings.Display.SectionHeader.dateFormat
            cell = _cell
        }
        return cell
    }
    
}

extension DisplayPreferenceViewModel {
    
    static func configure(cell: TimelinePostTableViewCell) {
        cell.selectionStyle = .none
        // set avatar
        cell.timelinePostView.avatarImageView.image = Asset.Logo.twidereAvatar.image
        UserDefaults.shared
            .observe(\.avatarStyle, options: [.initial, .new]) { defaults, _ in
                let avatarStyle = defaults.avatarStyle
                let animator = UIViewPropertyAnimator(duration: 0.3, timingParameters: UISpringTimingParameters())
                animator.addAnimations { [weak cell] in
                    guard let cell = cell else { return }
                    cell.timelinePostView.avatarImageView.layer.masksToBounds = true
                    cell.timelinePostView.avatarImageView.layer.cornerRadius = AvatarConfigurableViewConfiguration.cornerRadius(for: TimelinePostView.avatarImageViewSize, avatarStyle: avatarStyle)
                    switch avatarStyle {
                    case .circle:               cell.timelinePostView.avatarImageView.layer.cornerCurve = .circular
                    case .roundedSquare:        cell.timelinePostView.avatarImageView.layer.cornerCurve = .continuous
                    }
                }
                animator.startAnimation()
            }
            .store(in: &cell.observations)
        
        cell.timelinePostView.nameLabel.text = "Twidere"
        cell.timelinePostView.usernameLabel.text = "@TwidereProject"
        cell.timelinePostView.lockImageView.isHidden = true
        cell.timelinePostView.dateLabel.text = "5m"
        cell.timelinePostView.activeTextLabel.configure(with: L10n.Scene.Settings.Display.Preview.thankForUsingTwidereX)
        cell.separatorLine.isHidden = true
    }
    
    
    static func configureFontSizeSlider(cell: SlideTableViewCell) {
        cell.leadingLabel.font = .systemFont(ofSize: 12)
        cell.leadingLabel.text = "Aa"

        cell.trailingLabel.font = .systemFont(ofSize: 18)
        cell.trailingLabel.text = "Aa"
        
        // disable the superview of slider to prevent user directly control
        cell.container.isUserInteractionEnabled = false
        cell.slider.minimumValue = 0
        cell.slider.maximumValue = Float(UserDefaults.contentSizeCategory.count - 1)
        if let index = UserDefaults.contentSizeCategory.firstIndex(of: UserDefaults.shared.customContentSizeCatagory) {
            cell.slider.value = Float(index)
        }
        
        UserDefaults.shared.publisher(for: \.useTheSystemFontSize)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { useTheSystemFontSize in
                cell.slider.tintColor = useTheSystemFontSize ? .secondaryLabel : .systemBlue
                cell.slider.isUserInteractionEnabled = !useTheSystemFontSize
            })
            .store(in: &cell.disposeBag)
    }
    
}

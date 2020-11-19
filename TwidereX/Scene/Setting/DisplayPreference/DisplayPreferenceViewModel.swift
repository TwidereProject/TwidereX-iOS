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
    
    // input
    
    // output
    let sections: [Section] = [
        Section(header: "Preview", settings: [.preview]),
        Section(header: "Text", settings: [
            .useTheSystemFontSizeSwitch,
            .fontSizeSlider,
        ]),
        Section(header: "Date Format", settings: [.useTheSystemFontSizeSwitch]),
        Section(header: "Media", settings: [.useTheSystemFontSizeSwitch]),
    ]
    
    
}

extension DisplayPreferenceViewModel {
    
    enum Setting: CaseIterable {
        case preview
        
        case useTheSystemFontSizeSwitch
        case fontSizeSlider
        //case
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
            _cell.textLabel?.text = "Use the system font size"
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
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SlideTableViewCell.self), for: indexPath) as! SlideTableViewCell
            DisplayPreferenceViewModel.configureFontSizeSlider(cell: _cell)
            cell = _cell
        }
        return cell
    }
    
}

extension DisplayPreferenceViewModel {
    
    static func configure(cell: TimelinePostTableViewCell) {
        cell.selectionStyle = .none
        
        cell.timelinePostView.avatarImageView.image = Asset.Logo.twidereAvatar.image
        cell.timelinePostView.avatarImageView.layer.borderWidth = 1
        cell.timelinePostView.avatarImageView.layer.borderColor = UIColor.systemFill.cgColor
        
        cell.timelinePostView.nameLabel.text = "Twidere"
        cell.timelinePostView.usernameLabel.text = "@TwidereProject"
        cell.timelinePostView.lockImageView.isHidden = true
        cell.timelinePostView.dateLabel.text = "5m"
        cell.timelinePostView.activeTextLabel.text = "Thanks for using @TwidereProject!"
        cell.separatorLine.isHidden = true
    }
    
    
    static func configureFontSizeSlider(cell: SlideTableViewCell) {
        cell.leadingLabel.font = .preferredFont(forTextStyle: .caption1)
        cell.leadingLabel.text = "Aa"

        cell.trailingLabel.font = .preferredFont(forTextStyle: .callout)
        cell.trailingLabel.text = "Aa"
        
        cell.slider.minimumValue = 0
        cell.slider.maximumValue = Float(UserDefaults.contentSizeCategory.count - 1)
        
        let customContentSizeCatagory = CurrentValueSubject<UIContentSizeCategory, Never>(UserDefaults.shared.customContentSizeCatagory)
        if let index = UserDefaults.contentSizeCategory.firstIndex(of: customContentSizeCatagory.value) {
            cell.slider.value = Float(index)
        }
        
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        customContentSizeCatagory
            .dropFirst()
            .removeDuplicates()
            .sink { customContentSizeCatagory in
                UserDefaults.shared.customContentSizeCatagory = customContentSizeCatagory
                feedbackGenerator.impactOccurred()
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: customContentSizeCatagory: %s", ((#file as NSString).lastPathComponent), #line, #function, String(describing: customContentSizeCatagory))
            }
            .store(in: &cell.disposeBag)
        
        UserDefaults.shared.publisher(for: \.useTheSystemFontSize)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { useTheSystemFontSize in
                cell.slider.tintColor = useTheSystemFontSize ? .secondaryLabel : .systemBlue
                cell.slider.isUserInteractionEnabled = !useTheSystemFontSize
            })
            .store(in: &cell.disposeBag)
        
        cell.sliderPublisher
            .sink { value in
                let index = Int(round(value))
                cell.slider.value = Float(index)   // set back to move by step
                let selectContentSizeCatagory = UserDefaults.contentSizeCategory[index]
                customContentSizeCatagory.value = selectContentSizeCatagory
            }
            .store(in: &cell.disposeBag)
    }
    
}

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
import AppShared
import TwidereAsset
import TwidereLocalization
import TwidereUI
import TwitterMeta

final class DisplayPreferenceViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()

    // input
//    let customContentSizeCatagory: CurrentValueSubject<UIContentSizeCategory, Never>

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
    let fontSizeSlideTableViewCell = TableSlideTableViewCell()

    override init() {
//        customContentSizeCatagory = CurrentValueSubject(UserDefaults.shared.customContentSizeCatagory)
        super.init()

//        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
//        customContentSizeCatagory
//            .dropFirst()
//            .removeDuplicates()
//            .sink { customContentSizeCatagory in
//                feedbackGenerator.impactOccurred()
//                UserDefaults.shared.customContentSizeCatagory = customContentSizeCatagory
//            }
//            .store(in: &disposeBag)
    }
    
    
}

extension DisplayPreferenceViewModel {
    
    enum Setting {
        case preview

//        case useTheSystemFontSizeSwitch
//        case fontSizeSlider

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
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
            DisplayPreferenceViewModel.configure(cell: _cell)
            cell = _cell
        case .avatarStyle(let avatarStyle):
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TableViewCheckmarkTableViewCell.self), for: indexPath) as! TableViewCheckmarkTableViewCell
            let metaContent = Meta.convert(from: .plaintext(string: avatarStyle.text))
            _cell.primaryTextLabel.configure(content: metaContent)
            UserDefaults.shared
                .observe(\.avatarStyle, options: [.initial, .new]) { defaults, _ in
                    _cell.accessoryType = avatarStyle == defaults.avatarStyle ? .checkmark : .none
                }
                .store(in: &_cell.observations)
            cell = _cell
        case .dateFormat:
            let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TableViewEntryTableViewCell.self), for: indexPath) as! TableViewEntryTableViewCell
            _cell.iconImageView.isHidden = true
            let metaContent = Meta.convert(from: .plaintext(string: L10n.Scene.Settings.Display.SectionHeader.dateFormat))
            _cell.primaryTextLabel.configure(content: metaContent)
            cell = _cell
        }
        return cell
    }
    
}

extension DisplayPreferenceViewModel {
    
    static func configure(cell: StatusTableViewCell) {
        cell.selectionStyle = .none
        
        cell.statusView.viewModel.authorAvatarImage = Asset.Scene.Preference.twidereAvatar.image
        cell.statusView.viewModel.authorName = PlaintextMetaContent(string: "Twidere")
        cell.statusView.viewModel.authorUsername = "TwidereProject"
        cell.statusView.viewModel.protected = false
        cell.statusView.viewModel.timestamp = Date()
        cell.statusView.viewModel.dateTimeProvider = DateTimeSwiftProvider()
        let content = TwitterContent(content: L10n.Scene.Settings.Display.Preview.thankForUsingTwidereX)
        cell.statusView.viewModel.content = TwitterMetaContent.convert(content: content, urlMaximumLength: 16, twitterTextProvider: OfficialTwitterTextProvider())
        cell.statusView.isUserInteractionEnabled = false
        cell.separator.isHidden = true
    }

}

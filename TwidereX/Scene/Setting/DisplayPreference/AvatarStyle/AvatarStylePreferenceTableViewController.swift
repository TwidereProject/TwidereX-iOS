//
//  AvatarStylePreferenceTableViewController.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-31.
//  Copyright © 2020 Twidere. All rights reserved.
//

import UIKit

final class AvatarStylePreferenceTableViewController: UITableViewController {
    
}

extension AvatarStylePreferenceTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.Scene.Settings.Display.Text.avatarStyle
        view.backgroundColor = .systemGroupedBackground
        
        tableView.register(ListCheckmarkTableViewCell.self, forCellReuseIdentifier: String(describing: ListCheckmarkTableViewCell.self))
    }
    
}

extension AvatarStylePreferenceTableViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UserDefaults.AvatarStyle.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ListCheckmarkTableViewCell.self), for: indexPath) as! ListCheckmarkTableViewCell
        
        let avatarStyle = UserDefaults.AvatarStyle.allCases[indexPath.row]
        cell.titleLabel.text = avatarStyle.text
        UserDefaults.shared
            .observe(\.avatarStyle, options: [.initial, .new]) { defaults, _ in
                cell.accessoryType = defaults.avatarStyle == avatarStyle ? .checkmark : .none
            }
            .store(in: &cell.observations)
        
        return cell
    }
    
}

extension AvatarStylePreferenceTableViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedAvatarStyle = UserDefaults.AvatarStyle.allCases[indexPath.row]
        UserDefaults.shared.avatarStyle = selectedAvatarStyle
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

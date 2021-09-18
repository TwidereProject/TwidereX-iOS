//
//  UserProvider+UITableViewDelegate.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-12-24.
//  Copyright © 2020 Twidere. All rights reserved.
//

import os.log
import UIKit

extension UITableViewDelegate where Self: UserProvider {
    
    func handleTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        os_log("%{public}s[%{public}ld], %{public}s: indexPath %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)
//        guard let cell = tableView.cellForRow(at: indexPath) as? FriendshipTableViewCell else { return }
//        twitterUser(for: cell, indexPath: indexPath)
//            .sink { [weak self] twitterUser in
//                guard let self = self else { return }
//                guard let twitterUser = twitterUser else { return }
//
//                let profileViewModel = ProfileViewModel(context: self.context, twitterUser: twitterUser)
//                DispatchQueue.main.async {
//                    self.coordinator.present(scene: .profile(viewModel: profileViewModel), from: self, transition: .show)
//                }
//            }
//            .store(in: &disposeBag)
    }
    
}

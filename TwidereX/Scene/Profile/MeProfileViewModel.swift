//
//  MeProfileViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-28.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import TwitterAPI

final class MeProfileViewModel: ProfileViewModel {
    
    init(activeAuthenticationIndex: AuthenticationIndex?) {
        if let activeAuthenticationIndex = activeAuthenticationIndex {
            if let twitterAuthentication = activeAuthenticationIndex.twitterAuthentication,
               let twitterUser = twitterAuthentication.twitterUser {
                super.init(twitterUser: twitterUser)
            } else {
                super.init()
            }
        } else {
            super.init()
        }
        
        // FIXME: multi-platform support
        self.currentTwitterUser
            .sink { [weak self] currentTwitterUser in
                os_log("%{public}s[%{public}ld], %{public}s: current active twitter user: %s", ((#file as NSString).lastPathComponent), #line, #function, currentTwitterUser?.username ?? "<nil>")
                
                guard let self = self else { return }
                self.twitterUser.value = currentTwitterUser
            }
            .store(in: &disposeBag)
    }
    
}

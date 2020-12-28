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
    
    init(context: AppContext) {
        super.init(context: context, optionalTwitterUser: context.authenticationService.activeAuthenticationIndex.value?.twitterAuthentication?.twitterUser)
        
        self.currentTwitterUser
            .sink { [weak self] currentTwitterUser in
                os_log("%{public}s[%{public}ld], %{public}s: current active twitter user: %s", ((#file as NSString).lastPathComponent), #line, #function, currentTwitterUser?.username ?? "<nil>")
                
                guard let self = self else { return }
                self.twitterUser.value = currentTwitterUser
            }
            .store(in: &disposeBag)
    }
    
}

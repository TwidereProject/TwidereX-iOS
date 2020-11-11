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
            
    // input
    let context: AppContext
    
    // output
    
    init(context: AppContext) {
        self.context = context
        assert(Thread.isMainThread)
        if let activeAuthenticationIndex = context.authenticationService.activeAuthenticationIndex.value,
           let currentTwitterUser = activeAuthenticationIndex.twitterAuthentication?.twitterUser {
            super.init(twitterUser: currentTwitterUser)
        } else {
            super.init()
        }
        
        currentTwitterUser
            .sink { [weak self] currentTwitterUser in
                os_log("%{public}s[%{public}ld], %{public}s: current active twitter user: %s", ((#file as NSString).lastPathComponent), #line, #function, currentTwitterUser?.username ?? "<nil>")
                
                guard let self = self else { return }
                self.twitterUser.value = currentTwitterUser
            }
            .store(in: &disposeBag)
            
        
        context.authenticationService.activeAuthenticationIndex
            .map { $0?.twitterAuthentication?.twitterUser }
            .assign(to: \.value, on: currentTwitterUser)
            .store(in: &disposeBag)
    }
    
}

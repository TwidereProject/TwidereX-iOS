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
    let currentTwitterUser = CurrentValueSubject<TwitterUser?, Never>(nil)
    
    init(context: AppContext) {
        self.context = context
        super.init()
        
        currentTwitterUser
            .sink { [weak self] twitterUser in
                os_log("%{public}s[%{public}ld], %{public}s: current active twitter user: %s", ((#file as NSString).lastPathComponent), #line, #function, twitterUser?.screenName ?? "<nil>")
                
                guard let self = self else { return }
                self.bannerImageURL.value = twitterUser?.profileBannerURL.flatMap { URL(string: $0) }
                self.avatarImageURL.value = twitterUser?.avatarImageURL(size: .original)
                self.name.value = twitterUser?.name
                self.username.value = twitterUser?.screenName
                self.isFolling.value = twitterUser?.following
                self.bioDescription.value = twitterUser?.bioDescription
                self.url.value = twitterUser?.url
                self.location.value = twitterUser?.location
                self.friendsCount.value = twitterUser?.friendsCount.flatMap { Int(truncating: $0) }
                self.followersCount.value = twitterUser?.followersCount.flatMap { Int(truncating: $0) }
                self.listedCount.value = twitterUser?.listedCount.flatMap { Int(truncating: $0) }
            }
            .store(in: &disposeBag)
            
        
        context.authenticationService.currentTwitterUser
            .assign(to: \.value, on: currentTwitterUser)
            .store(in: &disposeBag)
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension MeProfileViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        os_log("%{public}s[%{public}ld], %{public}s: fetch %ld TwitterUser object", ((#file as NSString).lastPathComponent), #line, #function, controller.fetchedObjects?.count ?? 0)

        // set nil if not match any
        let twitterUser = controller.fetchedObjects?.first as? TwitterUser
        currentTwitterUser.value = twitterUser
    }
}

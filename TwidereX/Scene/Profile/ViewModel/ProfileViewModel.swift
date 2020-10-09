//
//  ProfileViewModel.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-9-27.
//

import os.log
import Foundation
import Combine
import CoreDataStack
import TwitterAPI

// please override this base class
class ProfileViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
        
    // output
    let userID: CurrentValueSubject<String?, Never>
    let bannerImageURL: CurrentValueSubject<URL?, Never>
    let avatarImageURL: CurrentValueSubject<URL?, Never>
    let name: CurrentValueSubject<String?, Never>
    let username: CurrentValueSubject<String?, Never>
    let isFolling: CurrentValueSubject<Bool?, Never>
    let bioDescription: CurrentValueSubject<String?, Never>
    let url: CurrentValueSubject<String?, Never>
    let location: CurrentValueSubject<String?, Never>
    let friendsCount: CurrentValueSubject<Int?, Never>
    let followersCount: CurrentValueSubject<Int?, Never>
    let listedCount: CurrentValueSubject<Int?, Never>
    
    override init() {
        self.userID = CurrentValueSubject(nil)
        self.bannerImageURL = CurrentValueSubject(nil)
        self.avatarImageURL = CurrentValueSubject(nil)
        self.name = CurrentValueSubject(nil)
        self.username = CurrentValueSubject(nil)
        self.isFolling = CurrentValueSubject(nil)
        self.bioDescription = CurrentValueSubject(nil)
        self.url = CurrentValueSubject(nil)
        self.location = CurrentValueSubject(nil)
        self.friendsCount = CurrentValueSubject(nil)
        self.followersCount = CurrentValueSubject(nil)
        self.listedCount = CurrentValueSubject(nil)
        super.init()
    }
    
    init(twitterUser: TwitterUser) {
        self.userID = CurrentValueSubject(twitterUser.idStr)
        self.bannerImageURL = CurrentValueSubject(twitterUser.profileBannerURL.flatMap { URL(string: $0) })
        self.avatarImageURL = CurrentValueSubject(twitterUser.avatarImageURL(size: .original))
        self.name = CurrentValueSubject(twitterUser.name)
        self.username = CurrentValueSubject(twitterUser.screenName)
        self.isFolling = CurrentValueSubject(twitterUser.following)
        self.bioDescription = CurrentValueSubject(twitterUser.bioDescription)
        self.url = CurrentValueSubject(twitterUser.url)
        self.location = CurrentValueSubject(twitterUser.location)
        self.friendsCount = CurrentValueSubject(twitterUser.friendsCountInt)
        self.followersCount = CurrentValueSubject(twitterUser.followersCountInt)
        self.listedCount = CurrentValueSubject(twitterUser.listedCountInt)
        super.init()
    }
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
}

extension ProfileViewModel {
    func update(twitterUser: TwitterUser?) {
        self.userID.value = twitterUser?.idStr
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
}

//
//  ViewStateStore.swift
//  TwidereX
//
//  Created by Cirno MainasuK on 2020-11-10.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Combine

struct ViewStateStore {
    var settingView = ViewState.SettingView()
    var aboutView = ViewState.AboutView()
}

enum ViewState { }

extension ViewState {
    struct SettingView {
        let presentSettingListEntryPublisher = PassthroughSubject<SettingListEntry, Never>()
    }
}

extension ViewState {
    struct AboutView {
        let aboutEntryPublisher = PassthroughSubject<AboutEntryType, Never>()
    }
}

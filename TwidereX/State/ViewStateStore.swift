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
}

enum ViewState { }

extension ViewState {
    struct SettingView {
        let presentSettingListEntryPublisher = PassthroughSubject<SettingListEntry, Never>()
    }
}

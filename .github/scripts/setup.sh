#!/bin/bash

# mock firebase config file
cp ./TwidereX/mock-GoogleService-Info.plist ./TwidereX/GoogleService-Info.plist

sudo gem install cocoapods-keys

# stub keys. DO NOT use in production
# set "TwidereX" project name to make cocoapods-keys using right project
pod keys set app_secret "twidere" "TwidereX"
pod keys set consumer_key "<consumer_key>" "TwidereX"
pod keys set consumer_key_secret "<consumer_key_secret>" "TwidereX"
pod keys set host_key_public "" "TwidereX"
pod keys set oauth_endpoint "oob" "TwidereX"
pod keys set oauth_endpoint_debug "oob" "TwidereX"

pod install
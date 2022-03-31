#!/bin/bash

sudo gem install cocoapods-keys

# set "TwidereX" project name to make cocoapods-keys using the right project
pod keys set app_secret ${APP_SECRET} "TwidereX"
pod keys set consumer_key ${CONSUMER_KEY} "TwidereX"
pod keys set consumer_key_secret ${CONSUMER_KEY_SECRET} "TwidereX"
pod keys set host_key_public ${HOST_KEY_PUBLIC} "TwidereX"
pod keys set oauth_endpoint ${OAUTH_ENDPOINT} "TwidereX"
pod keys set oauth_endpoint_debug "oob" "TwidereX"

pod install
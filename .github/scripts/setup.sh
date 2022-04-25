#!/bin/bash

sudo gem install cocoapods-keys

# set "TwidereX" project name to make cocoapods-keys using the right project
pod keys set app_secret ${APP_SECRET} "TwidereX"
pod keys set consumer_key ${CONSUMER_KEY} "TwidereX"
pod keys set consumer_key_secret ${CONSUMER_KEY_SECRET} "TwidereX"
pod keys set client_id "" "TwidereX"
pod keys set client_id_debug "" "TwidereX"
pod keys set host_key_public ${HOST_KEY_PUBLIC} "TwidereX"
pod keys set oauth_endpoint ${OAUTH_ENDPOINT} "TwidereX"
pod keys set oauth_endpoint_debug "oob" "TwidereX"
pod keys set oauth2_endpoint ${OAUTH2_ENDPOINT} "TwidereX"
pod keys set oauth2_endpoint_debug ${OAUTH2_ENDPOINT_DEBUG} "TwidereX"

pod install
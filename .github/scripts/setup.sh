#!/bin/bash

sudo gem install cocoapods-keys

# stub keys. DO NOT use in production
pod keys set app_secret "twidere"
pod keys set consumer_key "<consumer_key>"
pod keys set consumer_key_secret "<consumer_key_secret>"
pod keys set host_key_public ""
pod keys set oauth_endpoint "oob"
pod keys set oauth_endpoint_debug "oob"

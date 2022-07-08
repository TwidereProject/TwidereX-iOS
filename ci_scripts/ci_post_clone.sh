#!/bin/zsh

# Xcode Cloud scripts

set -xeu
set -o pipefail

# list hardware
system_profiler SPSoftwareDataType SPHardwareDataType

# install rbenv
brew install rbenv
which ruby
echo 'eval "$(rbenv init -)"' >> ~/.zprofile
source ~/.zprofile
which ruby

rbenv install 3.0.3
rbenv global 3.0.3
ruby --version

# install bundle gem
gem install bundle

# setup cocoapods
bundle install

# set "TwidereX" project name to make cocoapods-keys using the right project
bundle exec pod keys set app_secret ${APP_SECRET} "TwidereX"
bundle exec pod keys set consumer_key ${CONSUMER_KEY} "TwidereX"
bundle exec pod keys set consumer_key_secret ${CONSUMER_KEY_SECRET} "TwidereX"
bundle exec pod keys set client_id ${CLIENT_ID} "TwidereX"
bundle exec pod keys set client_id_debug ${CLIENT_ID_DEBUG} "TwidereX"
bundle exec pod keys set host_key_public ${HOST_KEY_PUBLIC} "TwidereX"
bundle exec pod keys set oauth_endpoint ${OAUTH_ENDPOINT} "TwidereX"
bundle exec pod keys set oauth_endpoint_debug "oob" "TwidereX"
bundle exec pod keys set oauth2_endpoint ${OAUTH2_ENDPOINT} "TwidereX"
bundle exec pod keys set oauth2_endpoint_debug ${OAUTH2_ENDPOINT_DEBUG} "TwidereX"
bundle exec pod keys set mastodon_notification_endpoint_debug ${MASTODON_NOTIFICATION_ENDPOINT_DEBUG} "TwidereX"
bundle exec pod keys set mastodon_notification_endpoint ${MASTODON_NOTIFICATION_ENDPOINT} "TwidereX"

bundle exec pod install

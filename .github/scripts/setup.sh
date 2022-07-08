#!/bin/bash

set -xeu
set -o pipefail

gem install bundle
bundle install

bundle exec arkana
bundle exec pod install
#!/bin/bash

set -xeu
set -o pipefail

gem install bundler
bundle install

bundle exec arkana
bundle exec pod install
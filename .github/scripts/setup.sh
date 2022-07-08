#!/bin/bash

gem install bundle
bundle install

bundle exec arkana
bundle exec pod install
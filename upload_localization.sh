#!/bin/zsh

# Upload iOS specific i18n files 
set -ev

SRCROOT=`pwd`
PODS_ROOT='Pods'

echo ${SRCROOT}

crowdin upload sources --config ./crowdin-upload.yml
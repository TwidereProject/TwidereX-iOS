#!/usr/bin/env bash

set -xeu
set -o pipefail

SDK="${SDK:-iphoneos}"
WORKSPACE="${WORKSPACE:-TwidereX.xcworkspace}"
SCHEME="${SCHEME:-TwidereX}"
CONFIGURATION=${CONFIGURATION:-Debug}

xcrun xcodebuild \
    -workspace "${WORKSPACE}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -sdk "${SDK}" \
    -parallelizeTargets \
    -showBuildTimingSummary \
    clean \
    build | xcpretty

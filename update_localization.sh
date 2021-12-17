#!/bin/zsh

set -ev

SRCROOT=`pwd`
PODS_ROOT='Pods'

echo ${SRCROOT}

# download translation resources
mkdir -p ./Localization/Crowdin
crowdin download --all

# prepare resources
INPUT_DIR="${SRCROOT}/Localization/StringsConvertor/input"
echo "Prepare resources at ${INPUT_DIR}"

if [[ -d ${INPUT_DIR}  ]]; then
    rm -rf ${INPUT_DIR}
fi

cp -R ${SRCROOT}/Localization/Crowdin/translation/ ${INPUT_DIR}

# convert resources
cd ${SRCROOT}/Localization/StringsConvertor 
sh ./scripts/build.sh

# copy strings
cp -R ${SRCROOT}/Localization/StringsConvertor/output/module/ ${SRCROOT}/TwidereSDK/Sources/TwidereLocalization/Resources
cp -R ${SRCROOT}/Localization/StringsConvertor/output/main/ ${SRCROOT}/TwidereX/Resources

# cleanup input & output
sh ./scripts/cleanup.sh

# swiftgen
cd ${SRCROOT}
echo "${PODS_ROOT}/SwiftGen/bin/swiftgen"

if [[ -f "${PODS_ROOT}/SwiftGen/bin/swiftgen" ]] then 
    "${PODS_ROOT}/SwiftGen/bin/swiftgen"
else
    echo "Run 'pod install' or update your CocoaPods installation."
fi

# cleanup translation resources
cd ${SRCROOT}
rm -rf ${SRCROOT}/Localization/Crowdin/translation

#!/bin/zsh

set -ev

# cleanup output
if [[ -d output ]]; then
    rm -rf output
fi
mkdir output

# convert
swift run
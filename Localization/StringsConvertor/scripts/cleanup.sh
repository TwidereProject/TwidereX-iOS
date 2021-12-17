#!/bin/zsh

set -ev

# cleanup
if [[ -d input ]]; then
    rm -rf input
fi

if [[ -d output ]]; then
    rm -rf output
fi

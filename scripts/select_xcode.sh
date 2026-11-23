#!/usr/bin/env bash
# Wählt die neueste stabile Xcode-Version auf dem GitHub-Runner.
set -euo pipefail
XCODE=$(ls -d /Applications/Xcode_*.app 2>/dev/null | grep -viE 'beta|rc|release_candidate' | sort -V | tail -1)
if [ -n "${XCODE}" ]; then
  sudo xcode-select -s "${XCODE}/Contents/Developer"
fi
xcodebuild -version

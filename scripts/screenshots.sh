#!/usr/bin/env bash
# Takes docs/screenshots/{loading,loaded,empty,failed}.png with the --mock-* launch arguments
# (step-4-tested only). match.png and profile.png need a tap; instructions are printed at the end.
set -eu
cd "$(git rev-parse --show-toplevel)"

SIM=$(xcrun simctl list devices available | grep -oE "iPhone [0-9]+ Pro \(" | sed 's/ ($//' | sort -t' ' -k2 -n | tail -1)
[[ -z "$SIM" ]] && SIM=$(xcrun simctl list devices available | grep -m1 -oE "iPhone[^(]*" | sed 's/ *$//')
APP=com.revaprasetya.stabledate
OUT=docs/screenshots
mkdir -p "$OUT"

xcrun simctl boot "$SIM" 2>/dev/null || true
open "$(xcode-select -p)/Applications/Simulator.app" 2>/dev/null || open -a Simulator 2>/dev/null || true
xcrun simctl ui "$SIM" appearance light
xcodebuild -project stable-date.xcodeproj -scheme Live -destination "platform=iOS Simulator,name=$SIM" \
  -derivedDataPath build build >/dev/null
xcrun simctl install "$SIM" build/Build/Products/Debug-iphonesimulator/stable-date.app

shot() {
  xcrun simctl terminate "$SIM" "$APP" 2>/dev/null || true
  xcrun simctl launch "$SIM" "$APP" "$1" >/dev/null
  sleep 3
  xcrun simctl io "$SIM" screenshot "$OUT/$2.png" >/dev/null 2>&1
  echo "✓ $OUT/$2.png"
}
shot --mock-loading loading
shot --mock-loaded  loaded
shot --mock-empty   empty
shot --mock-failed  failed

echo "match.png / profile.png: the app is running with --mock-loaded."
echo "  Tap ♥ on Sir Gallops-a-Lot, then: xcrun simctl io \"$SIM\" screenshot $OUT/match.png"
echo "  Relaunch, tap the card, then:      xcrun simctl io \"$SIM\" screenshot $OUT/profile.png"

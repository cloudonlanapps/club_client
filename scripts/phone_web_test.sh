#!/usr/bin/env bash
# Run integration test files as a web build in Chrome on an Android phone.
#
#   scripts/phone_web_test.sh <server_port> <out_dir> <example_dir>:<file> ...
#
#   server_port   port of a running test stack (just start-app-test-server <conf>)
#   out_dir       where the per-file logs and summary.txt go
#   example_dir   cl_club_app/example or cl_club_website/example
#   file          integration_test/<name>_test.dart
#
# Needs, before it runs:
#   - the phone on USB with USB debugging allowed (`adb devices` lists it);
#   - ChromeDriver matching the phone's Chrome, listening on port 4444, with
#     the Android SDK's adb on its PATH (Chrome for Testing has the builds);
#   - a web/ folder in each example used (`flutter create --platforms=web .`,
#     not committed; restore pubspec.lock and .metadata afterwards).
#
# Environment:
#   ANDROID_SERIAL   the phone's adb id, when more than one device is attached
#   EXTRA_DEFINES    more flutter flags, e.g. --dart-define=REAL_VIEWPORT=true
#                    to lay the app out at the phone's own size (#264)
#   FILE_TIMEOUT     seconds per file (default 900)
#
# Each file is built and run on its own (about 4-5 minutes); the result line
# (PASS / FAIL / TIMEOUT) goes to <out_dir>/summary.txt.
set -u
if [ $# -lt 3 ]; then
  sed -n '2,25p' "$0"
  exit 2
fi
PORT=$1
OUT=$2
shift 2
REPO=$(cd "$(dirname "$0")/.." && pwd)
WEB_PORT=8099
TIMEOUT=${FILE_TIMEOUT:-900}
mkdir -p "$OUT"
SUMMARY=$OUT/summary.txt
for item in "$@"; do
  dir=${item%%:*}
  file=${item#*:}
  name=$(basename "$file" .dart)
  adb reverse tcp:"$PORT" tcp:"$PORT" >/dev/null
  adb reverse tcp:$WEB_PORT tcp:$WEB_PORT >/dev/null
  adb shell input keyevent KEYCODE_WAKEUP >/dev/null
  log=$OUT/$name.log
  start=$(date +%s)
  # shellcheck disable=SC2086
  (cd "$REPO/$dir" && timeout -k 30 "$TIMEOUT" flutter drive -d web-server \
    --web-port $WEB_PORT --web-hostname localhost \
    --browser-name=android-chrome --no-android-emulator \
    --driver="$REPO/cl_club_app/example/test_driver/integration_test.dart" \
    --target="$file" \
    --dart-define=CLUB_API_BASE_URL=http://localhost:"$PORT"/v1 \
    --dart-define=SUDO_USERNAME=sudo --dart-define=SUDO_PASSWORD=testboot \
    ${EXTRA_DEFINES:-}) >"$log" 2>&1
  rc=$?
  took=$(($(date +%s) - start))
  if [ $rc -eq 124 ] || [ $rc -eq 137 ]; then
    res=TIMEOUT
  elif [ $rc -ne 0 ]; then
    res=FAIL
  elif grep -q 'All tests passed' "$log"; then
    res=PASS
  else
    res="UNKNOWN(rc=0)"
  fi
  echo "$res $dir/$file ${took}s" | tee -a "$SUMMARY"
done
echo "DONE" >>"$SUMMARY"

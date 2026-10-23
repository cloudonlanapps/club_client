#!/usr/bin/env bash
# Run integration test files as a web build in Chrome on an Android phone.
# `just phone-test` / `just phone-test-one` (justfile_phone_tests.just) set
# everything below up and call this script; run it directly only by hand.
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
#   DEVTOOLS_PORT    local port for the phone's Chrome DevTools socket (default 9223)
#
# Each file is built and run on its own (about 4-5 minutes); the result line
# (PASS / FAIL / TIMEOUT) goes to <out_dir>/summary.txt. While they run,
# scripts/phone_chrome_grant.py keeps the clipboard permissions granted to
# the test page, so a clipboard read does not wait on Chrome's prompt (#288);
# its log is <out_dir>/chrome_grant.log.
set -u
if [ $# -lt 3 ]; then
  sed -n '2,31p' "$0"
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

# Grant the test page the clipboard permissions in Chrome on the phone, so
# a test that reads the clipboard does not stop at Chrome's prompt (#288).
# ChromeDriver starts Chrome for each file, so the helper keeps granting
# while the files run; what it did goes to chrome_grant.log.
DEVTOOLS_PORT=${DEVTOOLS_PORT:-9223}
if ss -ltnH "sport = :$DEVTOOLS_PORT" | grep -q .; then
  echo "ERROR: port $DEVTOOLS_PORT is in use; set DEVTOOLS_PORT to a free one." >&2
  exit 1
fi
adb forward tcp:"$DEVTOOLS_PORT" localabstract:chrome_devtools_remote >/dev/null \
  || { echo "ERROR: adb forward of Chrome's DevTools socket failed" >&2; exit 1; }
python3 -I "$REPO/scripts/phone_chrome_grant.py" "$DEVTOOLS_PORT" "http://localhost:$WEB_PORT" \
  >"$OUT/chrome_grant.log" 2>&1 &
grant_pid=$!
trap 'kill "$grant_pid" 2>/dev/null; adb forward --remove tcp:"$DEVTOOLS_PORT" >/dev/null 2>&1' EXIT
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

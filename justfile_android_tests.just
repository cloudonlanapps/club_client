# The member app's UI integration suite as the Android app on a phone
# connected over USB (#262): cl_club_app/example built for Android (debug,
# so plain-HTTP test stacks are allowed) and run with `flutter test -d
# <phone>`, against a fresh isolated stack per server conf, like app-test
# (justfile_app_tests.just) and phone-test (justfile_phone_tests.just).
#
# A run needs only the phone, with USB debugging allowed, and the Android SDK
# (ANDROID_HOME, default ~/Android/Sdk; scripts/dev-env.sh sets it up). The
# stack's port is forwarded to the phone with `adb reverse`, so the app
# reaches it as localhost. Each file builds, installs and runs the app on its
# own, laid out at the phone's own size (REAL_VIEWPORT=true, #264; real=""
# for the forced desktop size). Logs and summary.txt go to
# .phone_test/runs/<time>-android/; the stack is torn down unless keep is set. ANDROID_SERIAL picks the phone when more
# than one device is attached.

ANDROID_TEST_FILE_TIMEOUT := "900"

# Internal: start a fresh stack from CONF and run each file matching TARGET
# (a glob under the member app example) on the phone as the Android app.
_android-test CONF TARGET keep="" real="1": _native-deploy
    #!/usr/bin/env bash
    set -uo pipefail
    export PATH="{{PHONE_ANDROID_HOME}}/platform-tools:$PATH"
    command -v adb >/dev/null || { echo "ERROR: no adb in {{PHONE_ANDROID_HOME}}/platform-tools (set ANDROID_HOME)." >&2; exit 1; }
    devices=$(adb devices | awk 'NR>1 && $2=="device" {print $1}')
    if [ -z "${ANDROID_SERIAL:-}" ]; then
        n=$(printf '%s\n' "$devices" | grep -c .)
        [ "$n" -eq 1 ] || { echo "ERROR: $n Android devices ready (adb devices); connect one, or set ANDROID_SERIAL." >&2; exit 1; }
        export ANDROID_SERIAL=$devices
    fi
    run_dir="{{PHONE_TEST_DIR}}/runs/$(date +%Y%m%d-%H%M%S)-android"
    mkdir -p "$run_dir"
    summary="$run_dir/summary.txt"

    json=$("{{BACKGROUND_SERVER}}" {{CONF}} start --auto-ports) || exit 1
    port=$(printf '%s' "$json" | jq -r .server_port)
    db_port=$(printf '%s' "$json" | jq -r .db_port)
    if [ -n "{{keep}}" ]; then
        trap 'echo "==> keeping server on port $port (stop: just stop-app-test-server $port $db_port {{CONF}})"; echo "==> logs: $run_dir"' EXIT
    else
        trap '"{{BACKGROUND_SERVER}}" {{CONF}} cleanup port=$port db_port=$db_port; echo "==> logs: $run_dir"' EXIT
    fi
    echo "==> Android app on $ANDROID_SERIAL, against port $port ({{CONF}})"
    adb reverse tcp:"$port" tcp:"$port" >/dev/null || { echo "ERROR: adb reverse failed" >&2; exit 1; }
    fail=0
    (
        cd "{{APP_EXAMPLE_DIR}}"
        for f in {{TARGET}}; do
            [ -e "$f" ] || { echo "    skip (no match): $f"; continue; }
            name=$(basename "$f" .dart)
            log="$run_dir/$name.log"
            adb shell input keyevent KEYCODE_WAKEUP >/dev/null
            start=$(date +%s)
            timeout -k 30 {{ANDROID_TEST_FILE_TIMEOUT}} flutter test "$f" -d "$ANDROID_SERIAL" \
                --dart-define=CLUB_API_BASE_URL=http://localhost:"$port"/v1 \
                --dart-define=SUDO_USERNAME=sudo \
                --dart-define=SUDO_PASSWORD=testboot {{ if real != "" { "--dart-define=REAL_VIEWPORT=true" } else { "" } }} >"$log" 2>&1
            rc=$?
            took=$(($(date +%s) - start))
            if [ $rc -eq 124 ] || [ $rc -eq 137 ]; then res=TIMEOUT
            elif [ $rc -ne 0 ]; then res=FAIL
            # A skip is not a pass (as in app-test): name it.
            elif grep -qE '~[0-9]+: All tests (passed|skipped)|~[0-9]+: Some tests' "$log"; then res=SKIP
            elif grep -q 'All tests passed' "$log"; then res=PASS
            else res="UNKNOWN(rc=0)"; fi
            echo "$res $f ${took}s" | tee -a "$summary"
            [ "$res" = PASS ] || [ "$res" = SKIP ] || fail=1
        done
        echo DONE >>"$summary"
        exit $fail
    ) || fail=1
    exit $fail

#   just android-test                         # every conf
#   just android-test app_test_server2.conf   # one conf
# Run the member app's integration suite as the Android app on the phone, once per server conf.
[group('app integration')]
android-test CONF="" keep="" real="1":
    #!/usr/bin/env bash
    set -u
    fail=0
    for conf in {{ if CONF == "" { APP_TEST_CONFS } else { CONF } }}; do
        just _android-test "$conf" "integration_test/workflow*_test.dart" "{{keep}}" "{{real}}" || fail=1
    done
    exit $fail

#   just android-test-one app_test_server1.conf workflow1_password_reset_by_user_test.dart [keep=1]
# Run one member app integration file as the Android app on the phone.
[group('app integration')]
android-test-one CONF FILE keep="" real="1": (_android-test (CONF) ("integration_test/" + FILE) keep real)

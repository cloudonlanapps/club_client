# The UI integration suites as a web build in Chrome on an Android phone
# connected over USB (#274): the member app's (cl_club_app/example) and the
# website's (cl_club_website/example), against a fresh isolated stack per
# server conf, like app-test and website-test (justfile_app_tests.just).
#
# A run needs only the phone, with USB debugging allowed. The recipe:
#   - reads the phone's Chrome version and fetches the matching ChromeDriver
#     from Chrome for Testing into .phone_test/chromedriver/ (gitignored),
#     then starts it on port 4444 with the Android SDK's adb on its PATH;
#   - creates a web/ folder in the example for the run and removes it after,
#     leaving no tracked file changed (the examples carry no web/);
#   - forwards the stack's port and the web port to the phone (adb reverse)
#     and runs each file through scripts/phone_web_test.sh, one at a time
#     (about 4-5 minutes each);
#   - tears the stack down unless keep is set.
#
# The app is laid out at the phone's own size (REAL_VIEWPORT=true, #264);
# pass real="" for the old forced desktop size. Logs and summary.txt go to
# .phone_test/runs/<time>/. ANDROID_SERIAL picks the phone when more than one
# device is attached.

PHONE_TEST_DIR := justfile_directory() / ".phone_test"
PHONE_ANDROID_HOME := env("ANDROID_HOME", env("HOME", "") / "Android/Sdk")
PHONE_CHROMEDRIVER_PORT := "4444"
PHONE_CFT_URL := "https://googlechromelabs.github.io/chrome-for-testing/latest-patch-versions-per-build-with-downloads.json"

# Internal: start a fresh stack from CONF and run the given
# "<example dir>:integration_test/<file>" items on the phone.
_phone-test CONF ITEMS keep="" real="1": _native-deploy
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
    chrome=$(adb shell dumpsys package com.android.chrome | sed -n 's/.*versionName=\([0-9.]*\).*/\1/p' | head -1)
    [ -n "$chrome" ] || { echo "ERROR: no Chrome on the phone $ANDROID_SERIAL." >&2; exit 1; }
    build=${chrome%.*}

    # ChromeDriver for the phone's Chrome build, fetched once per build.
    cd_dir="{{PHONE_TEST_DIR}}/chromedriver/$build"
    driver="$cd_dir/chromedriver-linux64/chromedriver"
    if [ ! -x "$driver" ]; then
        url=$(curl -fsS "{{PHONE_CFT_URL}}" | jq -r --arg b "$build" \
            '.builds[$b].downloads.chromedriver[]? | select(.platform=="linux64") | .url')
        [ -n "$url" ] || { echo "ERROR: Chrome for Testing has no ChromeDriver for Chrome $build." >&2; exit 1; }
        echo "==> fetching ChromeDriver for Chrome $build"
        mkdir -p "$cd_dir" && curl -fsSL "$url" -o "$cd_dir/cd.zip" && unzip -qo "$cd_dir/cd.zip" -d "$cd_dir" && rm -f "$cd_dir/cd.zip" \
            || { echo "ERROR: could not fetch $url" >&2; exit 1; }
    fi
    if curl -fsS -m 2 "localhost:{{PHONE_CHROMEDRIVER_PORT}}/status" >/dev/null 2>&1; then
        echo "ERROR: something already listens on port {{PHONE_CHROMEDRIVER_PORT}}; stop it first." >&2; exit 1
    fi

    run_dir="{{PHONE_TEST_DIR}}/runs/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$run_dir"
    driver_pid=""
    created_web=()
    stack_cleanup=""
    cleanup() {
        [ -n "$driver_pid" ] && kill "$driver_pid" 2>/dev/null
        for d in "${created_web[@]}"; do rm -rf "$d/web"; done
        [ -n "$stack_cleanup" ] && eval "$stack_cleanup"
        echo "==> logs: $run_dir"
    }
    trap cleanup EXIT

    "$driver" --port={{PHONE_CHROMEDRIVER_PORT}} >"$run_dir/chromedriver.log" 2>&1 &
    driver_pid=$!
    for _ in $(seq 20); do curl -fsS -m 1 "localhost:{{PHONE_CHROMEDRIVER_PORT}}/status" >/dev/null 2>&1 && break; sleep 0.5; done
    curl -fsS -m 1 "localhost:{{PHONE_CHROMEDRIVER_PORT}}/status" >/dev/null 2>&1 \
        || { echo "ERROR: ChromeDriver did not start; see $run_dir/chromedriver.log" >&2; exit 1; }

    # A web/ folder for each example the run uses. flutter create also
    # rewrites .metadata and may add files (README.md, a widget test); put
    # those back so nothing is left behind except web/, which cleanup removes.
    # Only the files it can touch are restored, so uncommitted work in the
    # example is kept; anything else it changed stops the run.
    for dir in $(printf '%s\n' {{ITEMS}} | cut -d: -f1 | sort -u); do
        [ -d "$dir/web" ] && continue
        keep_dir=$(mktemp -d)
        for f in .metadata .gitignore pubspec.yaml pubspec.lock analysis_options.yaml README.md; do
            [ -e "$dir/$f" ] && cp -p "$dir/$f" "$keep_dir/$f"
        done
        changed_before=$(git diff --name-only -- "$dir")
        new_before=$(git ls-files --others --exclude-standard -- "$dir")
        (cd "$dir" && flutter create --platforms=web --no-pub . >/dev/null) \
            || { echo "ERROR: flutter create --platforms=web failed in $dir" >&2; exit 1; }
        created_web+=("$dir")
        for f in .metadata .gitignore pubspec.yaml pubspec.lock analysis_options.yaml README.md; do
            if [ -e "$keep_dir/$f" ]; then cp -p "$keep_dir/$f" "$dir/$f"; else rm -f "$dir/$f"; fi
        done
        rm -rf "$keep_dir"
        comm -13 <(printf '%s\n' "$new_before" | sort) <(git ls-files --others --exclude-standard -- "$dir" | sort) \
            | grep -v "^$dir/web/" | xargs -r rm -f
        if [ "$(git diff --name-only -- "$dir")" != "$changed_before" ]; then
            echo "ERROR: flutter create changed tracked files in $dir:" >&2
            diff <(printf '%s\n' "$changed_before") <(git diff --name-only -- "$dir") >&2
            exit 1
        fi
    done

    json=$("{{BACKGROUND_SERVER}}" {{CONF}} start --auto-ports) || exit 1
    port=$(printf '%s' "$json" | jq -r .server_port)
    db_port=$(printf '%s' "$json" | jq -r .db_port)
    if [ -n "{{keep}}" ]; then
        stack_cleanup="echo '==> keeping server on port $port (stop: just stop-app-test-server $port $db_port {{CONF}})'"
    else
        stack_cleanup="'{{BACKGROUND_SERVER}}' {{CONF}} cleanup port=$port db_port=$db_port"
    fi
    echo "==> phone $ANDROID_SERIAL, Chrome $chrome, against port $port ({{CONF}})"
    export EXTRA_DEFINES="{{ if real != "" { "--dart-define=REAL_VIEWPORT=true" } else { "" } }}"
    scripts/phone_web_test.sh "$port" "$run_dir" {{ITEMS}}
    ! grep -qvE '^(PASS |DONE$)' "$run_dir/summary.txt"

#   just phone-test                         # both suites, every conf
#   just phone-test app_test_server2.conf   # both suites, one conf
#   just phone-test app_test_server1.conf app       # the member app's suite only
#   just phone-test app_test_server1.conf website real=""
# Run the integration suites in Chrome on the Android phone, once per server conf.
[group('app integration')]
phone-test CONF="" SUITE="" keep="" real="1":
    #!/usr/bin/env bash
    set -u
    case "{{SUITE}}" in
        "") dirs="{{APP_EXAMPLE_DIR}} {{WEBSITE_EXAMPLE_DIR}}" ;;
        app) dirs="{{APP_EXAMPLE_DIR}}" ;;
        website) dirs="{{WEBSITE_EXAMPLE_DIR}}" ;;
        *) echo "ERROR: SUITE is app, website or empty (both)." >&2; exit 2 ;;
    esac
    fail=0
    for conf in {{ if CONF == "" { APP_TEST_CONFS } else { CONF } }}; do
        # Each suite gets a fresh stack, as `just app-test` and
        # `just website-test` give it: the website's empty-site file needs
        # a server no test has written to (#302).
        for d in $dirs; do
            items=""
            for f in "$d"/integration_test/workflow*_test.dart; do
                [ -e "$f" ] && items="$items $d:integration_test/$(basename "$f")"
            done
            [ -n "$items" ] || continue
            just _phone-test "$conf" "$items" "{{keep}}" "{{real}}" || fail=1
        done
    done
    exit $fail

#   just phone-test-one app_test_server1.conf workflow1_password_reset_by_user_test.dart
#   just phone-test-one app_test_server1.conf workflow_emptysite_every_route_test.dart real=""
# Run one integration file (member app's or website's) in Chrome on the Android phone.
[group('app integration')]
phone-test-one CONF FILE keep="" real="1":
    #!/usr/bin/env bash
    set -u
    item=""
    for d in "{{APP_EXAMPLE_DIR}}" "{{WEBSITE_EXAMPLE_DIR}}"; do
        [ -e "$d/integration_test/{{FILE}}" ] && item="$d:integration_test/{{FILE}}"
    done
    [ -n "$item" ] || { echo "ERROR: no integration_test/{{FILE}} in either example." >&2; exit 2; }
    just _phone-test "{{CONF}}" "$item" "{{keep}}" "{{real}}"

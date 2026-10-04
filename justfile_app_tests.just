# UI integration suite — cl_club_app/example on the Linux desktop, against a
# fresh isolated club_server stack per server conf.
#
# The stack is started by native_deploy's background_server.sh (expected on
# PATH) from a conf at this repo's root; each conf clones club_server's main
# branch from git:
#   app_test_server1.conf  modules off, identity verification on
#   app_test_server2.conf  as p52club deploys: modules on, identity verification off
# Tests decide what to expect from GET /v1/capabilities, never from the club.

APP_EXAMPLE_DIR := "cl_club_app/example"
APP_TEST_FILE_TIMEOUT := "600"
APP_TEST_CONFS := "app_test_server1.conf app_test_server2.conf"

# Internal: start a fresh stack from CONF, run each file matching TARGET
# (a glob under cl_club_app/example/) with `flutter test -d linux`, and tear
# the stack down on exit (unless `keep` is non-empty).
_app-test CONF TARGET keep="":
    #!/usr/bin/env bash
    set -uo pipefail
    command -v background_server.sh >/dev/null 2>&1 || { echo "ERROR: background_server.sh (native_deploy) is not on PATH." >&2; exit 1; }
    json=$(background_server.sh {{CONF}} start --auto-ports) || exit 1
    base=$(printf '%s' "$json" | jq -r .base_url)
    port=$(printf '%s' "$json" | jq -r .server_port)
    db_port=$(printf '%s' "$json" | jq -r .db_port)
    if [ -n "{{keep}}" ]; then
        trap 'echo "==> keeping server $base (stop: just stop-app-test-server $port $db_port {{CONF}})" >&2' EXIT
    else
        trap 'background_server.sh {{CONF}} cleanup port=$port db_port=$db_port' EXIT
    fi
    echo "==> UI integration (linux) against $base ({{CONF}})"
    # A subshell keeps this shell at the repo root, where the trap's conf path resolves.
    (
        cd {{APP_EXAMPLE_DIR}}
        # Kill every process still carrying run id $1 in its environment.
        sweep_app_test_run() {
            local pids
            pids=$(grep -lsz "^APP_TEST_RUN_ID=$1\$" /proc/[0-9]*/environ | cut -d/ -f3)
            [ -z "$pids" ] && return 0
            echo "    swept leftover processes: $(echo $pids)"
            kill -KILL $pids 2>/dev/null || true
        }
        fail=0
        for f in {{TARGET}}; do
            [ -e "$f" ] || { echo "    skip (no match): $f"; continue; }
            echo "==> $f (timeout {{APP_TEST_FILE_TIMEOUT}}s)"
            out=$(mktemp)
            rcf=$(mktemp)
            # The flutter tool puts itself and the app under test in their
            # own sessions, out of reach of `timeout`'s process-group kill, and
            # an app left behind keeps the pipe to `tee` open: the run then
            # hangs forever (club_core#182). So mark this file's processes
            # with a run id they all inherit, escalate to SIGKILL, and sweep
            # whatever is still marked once `timeout` returns.
            run_id="apptest-$$-$RANDOM"
            trap 'sweep_app_test_run "$run_id"' EXIT
            { APP_TEST_RUN_ID="$run_id" timeout -k 30 {{APP_TEST_FILE_TIMEOUT}} flutter test "$f" -d linux \
                --dart-define=CLUB_API_BASE_URL="$base" \
                --dart-define=SUDO_USERNAME=sudo \
                --dart-define=SUDO_PASSWORD=testboot 2>&1; echo $? > "$rcf"; } | tee "$out" &
            tee_pid=$!
            until [ -s "$rcf" ]; do sleep 2; done
            sweep_app_test_run "$run_id"
            wait "$tee_pid"
            rc=$(cat "$rcf")
            rm -f "$rcf"
            if [ $rc -eq 124 ] || [ $rc -eq 137 ]; then echo "    [TIMEOUT] $f ({{CONF}})"; fail=1
            elif [ $rc -ne 0 ]; then echo "    [FAIL] $f ({{CONF}})"; fail=1
            elif grep -qE '~[0-9]+: All tests (passed|skipped)|~[0-9]+: Some tests' "$out"; then
                # A skip is not a pass: name it, with the reasons the tests gave.
                echo "    [SKIP] $f ({{CONF}})"
                grep -E '^\s+(known issue, club_core#[0-9]+|.* is (on|off) on this stack)' "$out" | sort -u | sed 's/^\s*/           /'
            else echo "    [PASS] $f ({{CONF}})"; fi
            rm -f "$out"
        done
        exit $fail
    )

#   just app-test                        # every conf, auto-teardown
#   just app-test app_test_server2.conf  # one conf
#   just app-test app_test_server1.conf keep=1
# Run the UI integration suite once per server conf (or against one).
[group('app integration')]
app-test CONF="" keep="":
    #!/usr/bin/env bash
    set -u
    fail=0
    for conf in {{ if CONF == "" { APP_TEST_CONFS } else { CONF } }}; do
        just _app-test "$conf" "integration_test/workflow*_test.dart" "{{keep}}" || fail=1
    done
    exit $fail

#   just app-test-one app_test_server1.conf workflow1_password_reset_by_user_test.dart [keep=1]
# Run one UI integration test file against one server conf.
[group('app integration')]
app-test-one CONF FILE keep="": (_app-test (CONF) ("integration_test/" + FILE) keep)

# Prints one JSON line (name, base_url, server_port, db_port, run_dir,
# tmux_session, server_log). Watch logs: tmux attach -t <tmux_session>
# Start a fresh isolated test server from a conf.
[group('app integration')]
start-app-test-server CONF="app_test_server1.conf":
    background_server.sh {{CONF}} start --auto-ports

# Pass the server_port and db_port that `start-app-test-server` printed.
# Stop an isolated test server and remove its run directory.
[group('app integration')]
stop-app-test-server PORT DB_PORT CONF="app_test_server1.conf":
    background_server.sh {{CONF}} cleanup port={{PORT}} db_port={{DB_PORT}}

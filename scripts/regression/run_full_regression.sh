#!/usr/bin/env bash
# Full regression of club_client, unattended, on three targets, with timing,
# server, device and network statistics. Read-only: it tests a fresh worktree
# and never edits, commits or files anything.
#
#   scripts/regression/run_full_regression.sh          # normally started by start_in_tmux.sh
#
# Suites, in this order unless SUITES names others (names and groups such as
# "linux mobile-web android" are in suites.sh; they run in the order given):
#   unit           just unit-test-all
#   linux-app      just app-test          (member app on the Linux desktop, both confs)
#   linux-website  just website-test      (website on the Linux desktop, both confs)
#   phone-web      just phone-test        (both suites as a web build in Chrome on the phone, both confs)
#   android        just android-test      (member app as the Android app on the phone, both confs)
# then one alone re-run of each failed integration file (RETRY_FAILED=1), to
# tell a flaky failure from one that repeats.
#
# Environment (all optional):
#   REF=origin/main      what to test; a fresh detached worktree is made at it
#   OUT=~/Work/tmp/regression/<time>   where everything is written
#   SUITES=all           or e.g. "linux mobile-web android" (suites.sh)
#   INTERVAL=15          seconds between metric samples
#   SUITE_TIMEOUT=43200  seconds before one suite is stopped (12 h)
#   RETRY_FAILED=1  RETRY_MAX=25
#   KEEP_WORKTREE=0      1 keeps the worktree the run made (it is removed by default)
#   WORKTREE=<path>      test this existing worktree as it stands, instead of
#                        making one at REF; a worktree given this way is never removed
#   ANDROID_SERIAL       the phone, when more than one device is attached
#   ONLY_FILE / ONLY_CONF   a smoke run: the integration suites run only this
#                        file (integration_test/<name>), against ONLY_CONF
#                        (default app_test_server1.conf)
#
# Output, in $OUT:
#   test_report.md       results per suite, conf and file; failures with excerpts
#   performance_log.md   time taken, server, device and network statistics
#   failures.tsv         one line per failed file (suite, conf, file, result, retry)
#   status.txt           what is running now (the agent reads this)
#   run.log  meta.txt  suites.tsv  suites/*.log  failures/  metrics/  server_logs/  phone_runs/  unit_logs/
set -uo pipefail

# Keep the machine awake for the whole run: re-exec under systemd-inhibit.
if [ -z "${REGRESSION_INHIBITED:-}" ] && command -v systemd-inhibit >/dev/null \
   && systemd-inhibit --what=idle:sleep --who=club-regression --why=check true >/dev/null 2>&1; then
    export REGRESSION_INHIBITED=1
    exec systemd-inhibit --what=idle:sleep:handle-lid-switch --who=club-regression \
        --why="club_client full regression" "$0" "$@"
fi

HERE=$(cd "$(dirname "$0")" && pwd)
SRC_REPO=$(cd "$HERE/../.." && pwd)
STAMP=$(date +%Y%m%d-%H%M%S)
REF=${REF:-origin/main}
OUT=${OUT:-$HOME/Work/tmp/regression/$STAMP}
WT=${WORKTREE:-$HOME/Work/tmp/worktrees/club_client-regression-$STAMP}
source "$HERE/suites.sh"
SUITES=$(expand_suites "${SUITES:-all}") || exit 2
INTERVAL=${INTERVAL:-15}
SUITE_TIMEOUT=${SUITE_TIMEOUT:-43200}
RETRY_FAILED=${RETRY_FAILED:-1}
RETRY_MAX=${RETRY_MAX:-25}
KEEP_WORKTREE=${KEEP_WORKTREE:-0}
COOLDOWN=${COOLDOWN:-60}
export PATH="${ANDROID_HOME:-$HOME/Android/Sdk}/platform-tools:$PATH"
export ADB=$(command -v adb || echo adb)
# A detached tmux may lack the desktop session's variables.
export DISPLAY=${DISPLAY:-:0}
[ -z "${XAUTHORITY:-}" ] && [ -f "/run/user/$UID/gdm/Xauthority" ] && export XAUTHORITY="/run/user/$UID/gdm/Xauthority"
export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$UID/bus}

mkdir -p "$OUT"/{suites,failures,unit_logs,phone_runs} || { echo "ERROR: cannot create $OUT" >&2; exit 1; }
ln -sfn "$OUT" "$(dirname "$OUT")/latest"
: >"$OUT/suites.tsv"

stamp() { while IFS= read -r l; do printf '%(%Y-%m-%d %H:%M:%S)T %s\n' -1 "$l"; done; }
note() { printf '%(%Y-%m-%d %H:%M:%S)T %s\n' -1 "$*" | tee -a "$OUT/run.log"; }
status() { printf 'state: %s\nsince: %(%Y-%m-%d %H:%M:%S)T\nout: %s\nworktree: %s\npid: %s\n' "$1" -1 "$OUT" "$WT" "$$" >"$OUT/status.txt"; }
phone_ready() { [ "$("$ADB" get-state 2>/dev/null)" = device ]; }

# ------------------------------------------------------------ restore on exit
RESTORE="$OUT/restore_settings.sh"
echo "#!/usr/bin/env bash" >"$RESTORE"; chmod +x "$RESTORE"
sampler_pid=""
finished=0
created_wt=0
cleanup() {
    status "finishing"
    echo cleanup >"$OUT/phase"
    touch "$OUT/stop"
    [ -n "$sampler_pid" ] && wait "$sampler_pid" 2>/dev/null
    note "restoring desktop and phone settings"
    bash "$RESTORE" >>"$OUT/run.log" 2>&1
    note "writing reports"
    python3 -I "$HERE/report.py" report "$OUT" >>"$OUT/run.log" 2>&1 || note "ERROR: report.py failed (see run.log)"
    if [ "$created_wt" = 1 ] && [ "$KEEP_WORKTREE" != 1 ] && [ -d "$WT" ]; then
        note "removing worktree $WT"
        git -C "$SRC_REPO" worktree remove --force "$WT" >>"$OUT/run.log" 2>&1 || note "WARN: could not remove $WT"
    fi
    if [ "$finished" = 1 ]; then status "done"; else status "stopped early (see run.log)"; fi
    note "finished: $OUT/test_report.md and $OUT/performance_log.md"
}
trap cleanup EXIT
trap 'note "interrupted"; exit 130' INT TERM HUP

status "preflight"
note "full regression: ref=$REF suites=[$SUITES] out=$OUT"

# ------------------------------------------------------------ preflight
{
    echo "started: $(date '+%F %T')"
    echo "ref: $REF"
    echo "suites: $SUITES"
    echo "host: $(hostname), $(nproc) CPUs, $(free -g | awk '/Mem:/{print $2}') GB RAM"
    echo "kernel: $(uname -r)"
    echo "display: DISPLAY=$DISPLAY session=${XDG_SESSION_TYPE:-?}"
    echo "flutter: $(flutter --version 2>&1 | head -1)"
    echo "dart: $(dart --version 2>&1 | head -1)"
    echo "just: $(just --version 2>&1)"
} >"$OUT/meta.txt"

need_phone=0
for s in $SUITES; do case $s in phone-web|android) need_phone=1 ;; esac; done
need_display=0
for s in $SUITES; do case $s in linux-app|linux-website) need_display=1 ;; esac; done
for t in just flutter dart jq tmux git python3 ss; do
    command -v "$t" >/dev/null || { note "ERROR: $t is not on PATH"; exit 1; }
done
if [ "$need_display" = 1 ] && ! xset q >/dev/null 2>&1; then
    note "WARN: no X display at $DISPLAY; the Linux suites will fail"
fi
if [ "$need_phone" = 1 ]; then
    if phone_ready; then
        {
            echo "phone: $("$ADB" shell getprop ro.product.model | tr -d '\r') ($("$ADB" get-serialno)), Android $("$ADB" shell getprop ro.build.version.release | tr -d '\r')"
            echo "phone chrome: $("$ADB" shell dumpsys package com.android.chrome | sed -n 's/.*versionName=\([0-9.]*\).*/\1/p' | head -1)"
        } >>"$OUT/meta.txt"
    else
        note "WARN: no phone ready (adb get-state); the phone suites will be recorded as not run"
    fi
fi

# Keep the desktop from blanking or locking (the Linux suites need it), and
# the phone's screen on while it is charging over USB. Undone in cleanup, or
# by running restore_settings.sh by hand if the run was killed.
if command -v gsettings >/dev/null; then
    for kv in "org.gnome.desktop.session idle-delay uint32 0" \
              "org.gnome.desktop.screensaver lock-enabled false" \
              "org.gnome.desktop.screensaver idle-activation-enabled false" \
              "org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'" \
              "org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'"; do
        set -- $kv
        schema=$1 key=$2; shift 2; val="${*: -1}"
        old=$(gsettings get "$schema" "$key" 2>/dev/null) || continue
        echo "gsettings set $schema $key $(printf '%q' "$old")" >>"$RESTORE"
        gsettings set "$schema" "$key" "$val" 2>>"$OUT/run.log"
    done
fi
if xset q >/dev/null 2>&1; then
    xset s off -dpms 2>>"$OUT/run.log"
    echo "xset s on +dpms" >>"$RESTORE"
fi
if [ "$need_phone" = 1 ] && phone_ready; then
    old=$("$ADB" shell settings get global stay_on_while_plugged_in | tr -d '\r')
    echo "'$ADB' shell settings put global stay_on_while_plugged_in ${old:-0}" >>"$RESTORE"
    "$ADB" shell svc power stayon usb
fi

# ------------------------------------------------------------ worktree
status "setup"
echo setup >"$OUT/phase"
python3 -I "$HERE/sampler.py" "$OUT" "$WT" "$INTERVAL" 2 &
sampler_pid=$!
setup_start=$(date +%s)
note "fetching and creating worktree $WT at $REF"
git -C "$SRC_REPO" fetch --quiet origin 2>&1 | stamp >>"$OUT/run.log"
if [ -d "$WT" ]; then
    # A worktree given with WORKTREE= is tested as it stands and never removed.
    note "using the existing worktree $WT as it is (REF is not applied; it is kept afterwards)"
else
    git -C "$SRC_REPO" worktree add --detach "$WT" "$REF" 2>&1 | stamp >>"$OUT/run.log"
    [ "${PIPESTATUS[0]}" -eq 0 ] || { note "ERROR: git worktree add failed"; exit 1; }
    created_wt=1
fi
echo "commit: $(git -C "$WT" log -1 --format='%h %s (%cd)' --date=short)" >>"$OUT/meta.txt"
note "flutter pub get in every package"
pubfail=0
while IFS= read -r p; do
    d=$(dirname "$p")
    (cd "$d" && flutter pub get) >>"$OUT/suites/setup.log" 2>&1 || { pubfail=1; note "WARN: pub get failed in ${d#$WT/}"; }
done < <(find "$WT" -name pubspec.yaml -not -path '*/.dart_tool/*' -not -path '*/build/*' -not -path '*/.native_deploy/*' | sort)
changed=$(git -C "$WT" status --porcelain)
[ -n "$changed" ] && { echo "pub get changed: $(echo $changed)" >>"$OUT/meta.txt"; note "WARN: pub get changed tracked files: $(echo $changed)"; }
printf 'setup\t%s\t%s\t%s\t%s\n' "$setup_start" "$(date +%s)" "$pubfail" "git worktree + flutter pub get" >>"$OUT/suites.tsv"

# ------------------------------------------------------------ suites
suite_cmd() {
    if [ -n "${ONLY_FILE:-}" ]; then   # a smoke run: one file, one conf, through the -one recipes
        local c=${ONLY_CONF:-app_test_server1.conf}
        case $1 in
            linux-app) echo "just app-test-one $c $ONLY_FILE"; return ;;
            linux-website) echo "just website-test-one $c $ONLY_FILE"; return ;;
            phone-web) echo "just phone-test-one $c $ONLY_FILE"; return ;;
            android) echo "just android-test-one $c $ONLY_FILE"; return ;;
        esac
    fi
    case $1 in
        unit) echo 'just unit-test-all' ;;
        linux-app) echo 'just app-test' ;;
        linux-website) echo 'just website-test' ;;
        phone-web) echo 'just phone-test' ;;
        android) echo 'just android-test' ;;
        *) return 1 ;;
    esac
}

run_suite() {   # run_suite <name> <command>
    local name=$1 cmd=$2 log="$OUT/suites/$1.log" start end rc before
    status "running $name"
    echo "$name" >"$OUT/phase"
    before=$(ls "$WT/.phone_test/runs" 2>/dev/null)
    start=$(date +%s)
    note "START $name: $cmd"
    (cd "$WT" && timeout -k 300 "$SUITE_TIMEOUT" bash -c "$cmd") </dev/null 2>&1 | stamp >"$log"
    rc=${PIPESTATUS[0]}
    end=$(date +%s)
    printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$start" "$end" "$rc" "$cmd" >>"$OUT/suites.tsv"
    note "END $name rc=$rc after $(( (end - start) / 60 )) min"
    # Keep the phone suites' per-file logs: the worktree is removed afterwards.
    for d in $(ls "$WT/.phone_test/runs" 2>/dev/null); do
        grep -qx "$d" <<<"$before" || cp -r "$WT/.phone_test/runs/$d" "$OUT/phone_runs/"
    done
    leftover=$(tmux ls 2>/dev/null | grep -c . || true)
    [ "$leftover" -gt 0 ] && echo "tmux sessions after $name: $(tmux ls 2>/dev/null | cut -d: -f1 | tr '\n' ' ')" >>"$OUT/run.log"
}

for s in $SUITES; do
    cmd=$(suite_cmd "$s") || { note "WARN: unknown suite $s, skipped"; continue; }
    case $s in
        phone-web|android)
            if ! phone_ready; then
                note "NOT RUN $s: no phone ready"
                now=$(date +%s)
                printf '%s\t%s\t%s\t%s\t%s\n' "$s" "$now" "$now" "NOT_RUN" "$cmd" >>"$OUT/suites.tsv"
                continue
            fi
            since=$("$ADB" shell "date '+%m-%d %H:%M:%S.000'" | tr -d '\r')
            "$ADB" shell svc power stayon usb >/dev/null 2>&1
            run_suite "$s" "$cmd"
            "$ADB" logcat -b crash -d -T "$since" >"$OUT/suites/$s.phone_crashes.log" 2>&1
            ;;
        unit)
            run_suite "$s" "$cmd"
            # unit-test-all writes its logs to /tmp/<pkg>-test.log; keep this run's.
            for f in $(grep -o '(log: /tmp/[^)]*)' "$OUT/suites/unit.log" | sed 's/(log: \(.*\))/\1/'); do
                cp "$f" "$OUT/unit_logs/" 2>/dev/null || note "WARN: missing unit log $f"
            done
            ;;
        *) run_suite "$s" "$cmd" ;;
    esac
    echo cooldown >"$OUT/phase"; status "cooldown after $s"; sleep "$COOLDOWN"
done

# ------------------------------------------------------------ retries
if [ "$RETRY_FAILED" = 1 ]; then
    python3 -I "$HERE/report.py" failures "$OUT" >"$OUT/retry_list.tsv" 2>>"$OUT/run.log" \
        || note "WARN: could not list failures for retry"
    n=$(grep -c . "$OUT/retry_list.tsv" 2>/dev/null || echo 0)
    if [ "$n" -gt 0 ]; then
        note "re-running $n failed integration file(s) alone (max $RETRY_MAX)"
        status "retrying failed files"
        echo retry >"$OUT/phase"
        head -n "$RETRY_MAX" "$OUT/retry_list.tsv" | while IFS=$'\t' read -r suite conf file; do
            case $suite in
                linux-app) cmd="just app-test-one $conf $file" ;;
                linux-website) cmd="just website-test-one $conf $file" ;;
                phone-web) cmd="just phone-test-one $conf $file" ;;
                android) cmd="just android-test-one $conf $file" ;;
                *) continue ;;
            esac
            case $suite in phone-web|android) phone_ready || { echo "@@RETRY-RESULT $suite $conf $file NOT_RUN 0"; continue; } ;; esac
            echo "@@RETRY $suite $conf $file"
            t0=$(date +%s)
            (cd "$WT" && timeout -k 120 3600 bash -c "$cmd") </dev/null 2>&1
            rc=$?
            echo "@@RETRY-RESULT $suite $conf $file $rc $(( $(date +%s) - t0 ))"
        done 2>&1 | stamp >"$OUT/suites/retry.log"
        for d in $(ls "$WT/.phone_test/runs" 2>/dev/null); do
            [ -e "$OUT/phone_runs/$d" ] || cp -r "$WT/.phone_test/runs/$d" "$OUT/phone_runs/"
        done
    fi
fi

finished=1

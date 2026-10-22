#!/usr/bin/env bash
# Start the full regression detached in tmux, so it runs for hours without a
# terminal (or Claude) attached. Prints the session name and output folder.
#
#   scripts/regression/start_in_tmux.sh                         # every suite, origin/main
#   scripts/regression/start_in_tmux.sh linux mobile-web android   # these, in this order
#   scripts/regression/start_in_tmux.sh android unit
#   REF=origin/beta_release scripts/regression/start_in_tmux.sh
#
# Names (in the order to run; see suites.sh): all, unit (every package's unit
# tests), linux (app + website on the desktop), mobile-web (both suites in
# Chrome on the phone), android (the member app on the phone), or one exact
# suite: linux-app linux-website phone-web.
# Arguments win over SUITES.
#
# Every variable run_full_regression.sh reads passes through. Watch it with
# `tmux attach -t <session>` (detach: Ctrl-b d); stop it with
# `tmux send-keys -t <session> C-c` (reports are still written).
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/suites.sh"
[ $# -gt 0 ] && SUITES="$*"
SUITES=$(expand_suites "${SUITES:-all}") || exit 2
export SUITES
echo "suites, in order: $SUITES"
if tmux ls 2>/dev/null | grep -q '^club-regression-'; then
    echo "ERROR: a regression is already running: $(tmux ls | grep '^club-regression-' | cut -d: -f1)" >&2
    exit 1
fi
# Precheck, so a missing phone or display is found now, not hours in.
# A problem stops the start; ALLOW_PROBLEMS=1 starts anyway (the affected
# suites then fail or are recorded as not run).
SUITES_CHECK=$SUITES
ADB_BIN="${ANDROID_HOME:-$HOME/Android/Sdk}/platform-tools/adb"
problems=()
case " $SUITES_CHECK " in *" phone-web "*|*" android "*)
    if [ ! -x "$ADB_BIN" ]; then
        problems+=("no adb at $ADB_BIN: phone-web and android cannot run")
    else
        ready=$("$ADB_BIN" devices | awk 'NR>1 && $2=="device"' | wc -l)
        other=$("$ADB_BIN" devices | awk 'NR>1 && NF && $2!="device" {print $1" ("$2")"}' | tr '\n' ' ')
        if [ "$ready" -eq 0 ]; then
            problems+=("no phone ready${other:+ (seen: $other- unlock it and allow USB debugging)}: phone-web and android would not run")
        elif [ "$ready" -gt 1 ] && [ -z "${ANDROID_SERIAL:-}" ]; then
            problems+=("$ready phones attached: set ANDROID_SERIAL")
        else
            model=$("$ADB_BIN" shell getprop ro.product.model | tr -d '\r')
            batt=$("$ADB_BIN" shell dumpsys battery | awk '/^ *level:/{print $2}')
            echo "phone: $model, battery ${batt:-?}%"
            case " $SUITES_CHECK " in *" phone-web "*)
                "$ADB_BIN" shell pm path com.android.chrome >/dev/null 2>&1 \
                    || problems+=("no Chrome on the phone: phone-web cannot run") ;;
            esac
        fi
    fi ;;
esac
case " $SUITES_CHECK " in *" linux-app "*|*" linux-website "*)
    DISPLAY=${DISPLAY:-:0} xset q >/dev/null 2>&1 \
        || problems+=("no X display at ${DISPLAY:-:0}: linux-app and linux-website would fail") ;;
esac
busy=$( { tmux ls 2>/dev/null || true; } | cut -d: -f1 | tr '\n' ' ')
[ -n "$busy" ] && problems+=("tmux sessions already running ($busy): test stacks or other runs make the UI suites flaky; stop them first")
if [ ${#problems[@]} -gt 0 ]; then
    for p in "${problems[@]}"; do echo "PROBLEM: $p" >&2; done
    if [ "${ALLOW_PROBLEMS:-}" != 1 ]; then
        echo "Not started. Fix the above, drop those suites with SUITES=..., or set ALLOW_PROBLEMS=1." >&2
        exit 1
    fi
    echo "ALLOW_PROBLEMS=1: starting anyway." >&2
fi

STAMP=$(date +%Y%m%d-%H%M%S)
export OUT=${OUT:-$HOME/Work/tmp/regression/$STAMP}
export WORKTREE=${WORKTREE:-$HOME/Work/tmp/worktrees/club_client-regression-$STAMP}
session="club-regression-$STAMP"
mkdir -p "$OUT"
vars=""
for v in OUT WORKTREE REF SUITES INTERVAL SUITE_TIMEOUT RETRY_FAILED RETRY_MAX KEEP_WORKTREE COOLDOWN \
         ONLY_FILE ONLY_CONF ANDROID_SERIAL ANDROID_HOME DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS PATH; do
    [ -n "${!v:-}" ] && vars+="export $v=$(printf '%q' "${!v}"); "
done
tmux new-session -d -s "$session" \
    "$vars bash $(printf '%q' "$HERE/run_full_regression.sh") 2>&1 | tee -a $(printf '%q' "$OUT/console.log")"
echo "session: $session"
echo "out: $OUT"
echo "status: $OUT/status.txt"

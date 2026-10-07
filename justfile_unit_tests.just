# Unit / widget tests — no live server, no device target.
#
# These run on the host VM and cover every package's test/ dir (widget tests
# use provider overrides for fake clients). The SDK's own tests live with it in
# cloudonlanapps/club_sdk; app integration is in the per-target app files.

# Run all tests in a single package, e.g. `just unit-test cl_club_members`.
[group('unit tests')]
unit-test PKG:
    @echo "==> {{PKG}} tests"
    cd {{PKG}} && flutter test -j 1

# Continues on failure; writes each package's output to /tmp/<pkg>-test.log and
# prints a final pass/fail summary. Does NOT touch the live-server suites.
# Run every package's unit + widget tests (host VM, no server).
[group('unit tests')]
unit-test-all:
    #!/usr/bin/env bash
    set -u
    pkgs=(cl_club_admin cl_club_app cl_club_branding cl_club_communication \
          cl_club_credits cl_club_evaluation \
          cl_club_events cl_club_forms \
          cl_club_members cl_club_website \
          cl_club_venues cl_member_auth cl_member_onboarding cl_member_zone \
          cl_remote_store cl_server_config ui_lib \
          cl_club_app/example cl_club_website/example)
    declare -A status
    for pkg in "${pkgs[@]}"; do
        log="/tmp/${pkg//\//_}-test.log"
        echo "==> $pkg (log: $log)"
        (cd "$pkg" && flutter test -j 1) >"$log" 2>&1
        if [ $? -eq 0 ]; then status[$pkg]=PASS; else status[$pkg]=FAIL; fi
    done
    echo
    echo "==> Summary"
    fail=0
    for pkg in "${pkgs[@]}"; do
        printf "    %-25s %s\n" "$pkg" "${status[$pkg]}"
        [ "${status[$pkg]}" = "FAIL" ] && fail=1
    done
    exit $fail

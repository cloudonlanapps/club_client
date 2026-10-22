# Suite names for the regression scripts; sourced, not run.
#
# expand_suites <name>...  prints the suites to run, in the order given, each
# once. Names may be a suite or a group:
#   unit           unit                 (just unit-test-all: every package's unit tests)
#   linux          linux-app linux-website
#   mobile-web     phone-web            (also: phone-web, web, phone)
#   android        android
#   all            unit linux-app linux-website phone-web android
# Exact suites: unit linux-app linux-website phone-web android
# Commas or spaces separate names. Returns 1 and names the unknown ones on
# stderr.
ALL_SUITES="unit linux-app linux-website phone-web android"
expand_suites() {
    local out=() bad=() n s
    for n in $(echo "$*" | tr ',' ' ' | tr 'A-Z' 'a-z'); do
        case $n in
            all|full) set -- $ALL_SUITES ;;
            linux) set -- linux-app linux-website ;;
            mobile-web|phone-web|web|phone) set -- phone-web ;;
            unit|android|linux-app|linux-website) set -- "$n" ;;
            *) bad+=("$n"); continue ;;
        esac
        for s in "$@"; do
            [[ " ${out[*]} " == *" $s "* ]] || out+=("$s")
        done
    done
    if [ ${#bad[@]} -gt 0 ]; then
        echo "unknown suite name(s): ${bad[*]} (use: all unit linux mobile-web android, or one of: linux-app linux-website phone-web)" >&2
        return 1
    fi
    echo "${out[*]}"
}

#!/usr/bin/env bash
# Sample Chrome's CPU and memory on an Android phone while tests run.
#
#   scripts/phone_perf_sample.sh <out.tsv> [interval_seconds]
#
# Every interval (default 30 s) it appends one row per Chrome process:
# time, process, CPU %, resident memory, the phone's free memory (kB) and
# battery temperature (tenths of °C). Stop it with Ctrl-C.
#
# Set ANDROID_SERIAL when more than one device is attached. Note that a
# debug web build (what flutter drive runs) is much heavier than a release
# build, so these numbers are not what a member's phone sees.
set -u
if [ $# -lt 1 ]; then
  sed -n '2,13p' "$0"
  exit 2
fi
OUT=$1
INTERVAL=${2:-30}
echo -e "time\tproc\tcpu\trss\tmemavail_kb\tbatt_temp" >"$OUT"
while true; do
  t=$(date +%H:%M:%S)
  mem=$(adb shell grep MemAvailable /proc/meminfo </dev/null | awk '{print $2}')
  temp=$(adb shell dumpsys battery </dev/null | awk '/temperature/{print $2}')
  adb shell top -b -n 1 -o PID,%CPU,RES,ARGS </dev/null |
    grep -E 'com.android.chrome' | grep -v grep |
    awk -v t="$t" -v m="$mem" -v b="$temp" \
      '{print t"\t"$4"\t"$2"\t"$3"\t"m"\t"b}' >>"$OUT"
  sleep "$INTERVAL"
done

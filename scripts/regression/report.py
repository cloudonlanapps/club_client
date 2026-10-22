#!/usr/bin/env python3
"""Build the regression's reports from what run_full_regression.sh wrote.

    report.py report   <out_dir>   writes test_report.md, performance_log.md, failures.tsv
    report.py failures <out_dir>   prints "suite<TAB>conf<TAB>file" for each failed
                                   integration file (the retry list)
"""
import collections
import csv
import glob
import os
import re
import statistics
import sys
import time

TS = re.compile(r"^(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d) ?(.*)$")
EXCERPT = re.compile(
    r"\[E\]|EXCEPTION CAUGHT|Expected:|Actual:|Which:|Test failed|TimeoutException|"
    r"Error:|ERROR|Exception:|failed|FAIL|was not found|No element|Bad state", re.I)
INTEGRATION = {"linux-app", "linux-website", "phone-web", "android"}
SUITE_TITLE = {
    "setup": "Setup (worktree, pub get)",
    "unit": "Unit tests (just unit-test-all)",
    "linux-app": "Member app on Linux (just app-test)",
    "linux-website": "Website on Linux (just website-test)",
    "phone-web": "Web build in Chrome on the phone (just phone-test)",
    "android": "Android app on the phone (just android-test)",
}


def epoch(s):
    return time.mktime(time.strptime(s, "%Y-%m-%d %H:%M:%S"))


def dur(sec):
    if sec is None:
        return "–"
    sec = int(sec)
    h, r = divmod(sec, 3600)
    m, s = divmod(r, 60)
    return f"{h}h{m:02d}m" if h else (f"{m}m{s:02d}s" if m else f"{s}s")


def lines_of(path):
    out = []
    try:
        with open(path, errors="replace") as f:
            for raw in f:
                raw = raw.rstrip("\n").replace("\r", "")
                m = TS.match(raw)
                out.append((m.group(1), m.group(2)) if m else (None, raw))
    except OSError:
        pass
    return out


def excerpt(text_lines, limit=25):
    picked = [l for l in text_lines if EXCERPT.search(l)]
    return (picked or text_lines[-limit:])[:limit]


def file_lines(path):
    try:
        with open(path, errors="replace") as f:
            return [l.rstrip("\n").replace("\r", "") for l in f]
    except OSError:
        return []


# ------------------------------------------------------------ suites.tsv

def read_suites(out):
    rows = []
    try:
        with open(os.path.join(out, "suites.tsv")) as f:
            for line in f:
                p = line.rstrip("\n").split("\t")
                if len(p) >= 4:
                    rows.append({"name": p[0], "start": float(p[1]), "end": float(p[2]),
                                 "rc": p[3], "cmd": p[4] if len(p) > 4 else ""})
    except OSError:
        pass
    return rows


# ------------------------------------------------------------ parsers

Result = collections.namedtuple("Result", "suite conf file result seconds log excerpt notes")


def parse_unit(out, suite):
    log = os.path.join(out, "suites", f"{suite}.log")
    lines = lines_of(log)
    starts = []  # (pkg, ts, logpath)
    summary = {}
    in_summary = False
    end_ts = None
    for ts, l in lines:
        m = re.match(r"==> (\S+) \(log: (.*)\)$", l)
        if m:
            starts.append((m.group(1), ts, m.group(2)))
        if l.startswith("==> Summary"):
            in_summary, end_ts = True, ts
        m = re.match(r"\s{4}(\S+)\s+(PASS|FAIL)\s*$", l)
        if in_summary and m:
            summary[m.group(1)] = m.group(2)
    results = []
    for i, (pkg, ts, logpath) in enumerate(starts):
        nxt = starts[i + 1][1] if i + 1 < len(starts) else end_ts
        secs = epoch(nxt) - epoch(ts) if ts and nxt else None
        local = os.path.join(out, "unit_logs", os.path.basename(logpath))
        res = summary.get(pkg, "NO RESULT")
        exc, notes = [], ""
        if res != "PASS":
            body = file_lines(local)
            failed = [re.sub(r"^.*?-\d+: ", "", l) for l in body if l.rstrip().endswith("[E]")]
            notes = "; ".join(sorted(set(failed))[:10])
            exc = excerpt(body)
        results.append(Result(suite, "-", pkg, res, secs, local, exc, notes))
    return results


def parse_integration(out, suite, log=None):
    log = log or os.path.join(out, "suites", f"{suite}.log")
    lines = lines_of(log)
    results, stacks, errors = [], [], []
    conf = "?"
    file_start = {}
    section = []           # lines since the current file started (linux)
    stack_start = None
    pending = []           # phone/android results waiting for their logs dir
    skip_reasons = None
    for i, (ts, l) in enumerate(lines):
        m = (re.match(r"==> UI integration \(linux\), \S+ against \S+ \((\S+)\)", l)
             or re.match(r"==> phone \S+, Chrome \S+, against port \d+ \((\S+)\)", l)
             or re.match(r"==> Android app on \S+, against port \d+ \((\S+)\)", l))
        if m:
            conf = m.group(1)
        if re.match(r"==> starting \S+", l):
            stack_start = ts
        if re.match(r"\s+ready\.$", l) and stack_start and ts:
            stacks.append(epoch(ts) - epoch(stack_start))
            stack_start = None
        if l.startswith("ERROR") or "ERROR:" in l[:12]:
            errors.append(f"{ts or ''} {l}".strip())
        # Linux: "==> integration_test/x.dart (timeout 600s)" ... "[PASS] x (conf)"
        m = re.match(r"==> (integration_test/\S+) \(timeout", l)
        if m:
            file_start[m.group(1)] = ts
            section = []
            skip_reasons = None
            continue
        m = re.match(r"\s+\[(PASS|FAIL|TIMEOUT|SKIP)\] (\S+) \((\S+)\)", l)
        if m:
            res, f, c = m.groups()
            st = file_start.get(f)
            secs = epoch(ts) - epoch(st) if ts and st else None
            exc = excerpt(section) if res in ("FAIL", "TIMEOUT") else []
            results.append(Result(suite, c, f, res, secs, log, exc, ""))
            if res == "SKIP":
                skip_reasons = len(results) - 1
            section = []
            continue
        if skip_reasons is not None and re.match(r"\s{11}\S", l):
            r = results[skip_reasons]
            results[skip_reasons] = r._replace(notes=(r.notes + "; " if r.notes else "") + l.strip())
            continue
        section.append(l)
        # Phone / Android: "PASS dir/integration_test/x.dart 123s"
        m = re.match(r"(PASS|FAIL|TIMEOUT|SKIP|UNKNOWN\S*) (\S+\.dart) (\d+)s$", l)
        if m:
            pending.append((conf, m.group(2), m.group(1), int(m.group(3))))
            continue
        m = re.match(r"==> logs: (\S+)", l)
        if m:
            run = os.path.join(out, "phone_runs", os.path.basename(m.group(1).rstrip("/")))
            for c, f, res, secs in pending:
                flog = os.path.join(run, os.path.basename(f)[:-5] + ".log")
                exc = excerpt(file_lines(flog)) if res not in ("PASS", "SKIP") else []
                notes = ""
                if res == "SKIP":
                    notes = "; ".join(sorted({x.strip() for x in file_lines(flog)
                                              if re.search(r"known issue|is (on|off) on this stack", x)}))
                results.append(Result(suite, c, f, res, secs, flog, exc, notes))
            pending = []
    for c, f, res, secs in pending:   # no logs line (the run was cut short)
        results.append(Result(suite, c, f, res, secs, log, [], "per-file log not located"))
    return results, stacks, errors


def parse_retries(out):
    retried = {}
    for ts, l in lines_of(os.path.join(out, "suites", "retry.log")):
        m = re.match(r"@@RETRY-RESULT (\S+) (\S+) (\S+) (\S+) (\d+)", l)
        if m:
            suite, conf, f, rc, secs = m.groups()
            retried[(suite, conf, os.path.basename(f))] = (
                "NOT RUN" if rc == "NOT_RUN" else ("PASS" if rc == "0" else f"FAIL (rc={rc})"), int(secs))
    return retried


def collect(out):
    suites = read_suites(out)
    results, stacks, errors = [], {}, {}
    for s in suites:
        if s["name"] == "unit":
            results += parse_unit(out, s["name"])
        elif s["name"] in INTEGRATION:
            r, st, er = parse_integration(out, s["name"])
            results += r
            stacks[s["name"]] = st
            errors[s["name"]] = er
    return suites, results, stacks, errors


def failed(r):
    return r.result not in ("PASS", "SKIP")


# ------------------------------------------------------------ metrics

def tsv(out, name):
    path = os.path.join(out, "metrics", name)
    try:
        with open(path) as f:
            return list(csv.DictReader(f, delimiter="\t"))
    except OSError:
        return []


def nums(rows, key):
    out = []
    for r in rows:
        try:
            out.append(float(r[key]))
        except (KeyError, TypeError, ValueError):
            pass
    return out


def stats(vals, fmt="{:.0f}"):
    if not vals:
        return "–", "–", "–"
    p95 = sorted(vals)[max(0, int(len(vals) * 0.95) - 1)]
    return fmt.format(statistics.mean(vals)), fmt.format(p95), fmt.format(max(vals))


def counter_delta(rows, key_field):
    """Sum of increases of cumulative rx/tx counters per key over rows (in time order)."""
    last, tot = {}, collections.defaultdict(lambda: [0, 0])
    for r in rows:
        k = r[key_field]
        cur = (int(r.get("rx_bytes") or r.get("rx_bytes_total") or 0),
               int(r.get("tx_bytes") or r.get("tx_bytes_total") or 0))
        if k in last:
            for i in (0, 1):
                d = cur[i] - last[k][i]
                if d > 0:
                    tot[k][i] += d
        last[k] = cur
    return tot


def mb(b):
    if b < 1e6:
        return f"{b / 1e3:,.1f} KB"
    return f"{b / 1e6:,.1f} MB" if b < 1e9 else f"{b / 1e9:,.2f} GB"


ACCESS = re.compile(r'"(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS) (\S+) HTTP/[\d.]+" (\d{3})')


def server_requests(out):
    """Per phase: request counts by status class, top endpoints, 5xx, tracebacks."""
    first_phase = {r["copy"]: r["phase"] for r in tsv(out, "server_logs.tsv")}
    per = collections.defaultdict(lambda: {"n": 0, "status": collections.Counter(),
                                           "ep": collections.Counter(), "5xx": collections.Counter(),
                                           "tb": 0, "logs": 0, "unmatched": 0})
    for path in sorted(glob.glob(os.path.join(out, "server_logs", "*.log"))):
        ph = first_phase.get(path, "unknown")
        d = per[ph]
        d["logs"] += 1
        matched = 0
        for l in file_lines(path):
            m = ACCESS.search(l)
            if m:
                matched += 1
                method, url, code = m.groups()
                ep = re.sub(r"/\d+(?=/|$)", "/{id}", url.split("?")[0])
                d["n"] += 1
                d["status"][code[0] + "xx"] += 1
                d["ep"][f"{method} {ep}"] += 1
                if code[0] == "5":
                    d["5xx"][f"{code} {method} {ep}"] += 1
            if "Traceback (most recent call last)" in l:
                d["tb"] += 1
        if not matched:
            d["unmatched"] += 1
    return per


# ------------------------------------------------------------ reports

def write_reports(out):
    suites, results, stacks, errors = collect(out)
    retried = parse_retries(out)
    meta = file_lines(os.path.join(out, "meta.txt"))
    fails = [r for r in results if failed(r)]
    for r in fails:   # keep each failure's excerpt and log beside the report
        name = f"{r.suite}-{r.conf}-{os.path.basename(r.file)}".replace("/", "_")
        with open(os.path.join(out, "failures", name + ".txt"), "w") as f:
            f.write(f"{r.suite} {r.conf} {r.file}: {r.result}\nlog: {r.log}\n\n")
            f.write("\n".join(r.excerpt) + "\n")

    with open(os.path.join(out, "failures.tsv"), "w") as f:
        f.write("suite\tconf\tfile\tresult\tseconds\tretry\tlog\n")
        for r in fails:
            rt = retried.get((r.suite, r.conf, os.path.basename(r.file)), ("not retried", 0))[0]
            f.write(f"{r.suite}\t{r.conf}\t{r.file}\t{r.result}\t{int(r.seconds or 0)}\t{rt}\t{r.log}\n")

    total_start = min((s["start"] for s in suites), default=None)
    total_end = max((s["end"] for s in suites), default=None)
    T = []
    T.append("# Full regression — test report\n")
    T += [f"- {m}" for m in meta]
    T.append(f"- total time: {dur(total_end - total_start) if suites else '–'}")
    T.append(f"- output: `{out}`\n")

    T.append("## Summary\n")
    T.append("| suite | result | files | pass | skip | fail | time |")
    T.append("|---|---|---|---|---|---|---|")
    for s in suites:
        rs = [r for r in results if r.suite == s["name"]]
        c = collections.Counter("PASS" if r.result == "PASS" else "SKIP" if r.result == "SKIP" else "FAIL" for r in rs)
        rc = s["rc"]
        verdict = ("NOT RUN" if rc == "NOT_RUN" else "TIMED OUT" if rc in ("124", "137")
                   else "PASS" if rc == "0" else "FAIL")
        if s["name"] == "setup":
            verdict = "ok" if rc == "0" else "pub get failed somewhere"
        T.append(f"| {SUITE_TITLE.get(s['name'], s['name'])} | {verdict} | {len(rs) or '–'} | "
                 f"{c['PASS']} | {c['SKIP']} | {c['FAIL']} | {dur(s['end'] - s['start'])} |")
    T.append("")

    T.append(f"## Failures ({len(fails)})\n")
    if not fails:
        T.append("None.\n")
    else:
        T.append("Retry = the file run once more on its own, after every suite. "
                 "PASS on retry means flaky; FAIL on retry means it repeats.\n")
        T.append("| # | suite | conf | file | result | time | retry |")
        T.append("|---|---|---|---|---|---|---|")
        for i, r in enumerate(fails, 1):
            rt = retried.get((r.suite, r.conf, os.path.basename(r.file)), ("not retried", 0))[0]
            T.append(f"| {i} | {r.suite} | {r.conf} | `{r.file}` | {r.result} | {dur(r.seconds)} | {rt} |")
        T.append("")
        for i, r in enumerate(fails, 1):
            T.append(f"### {i}. {r.suite} · {r.conf} · `{r.file}` — {r.result}\n")
            T.append(f"log: `{r.log}`")
            if r.notes:
                T.append(f"failing tests: {r.notes}")
            T.append("\n```\n" + "\n".join(r.excerpt[:25]) + "\n```\n")

    suite_errors = [(n, e) for n, es in errors.items() for e in es]
    bad_suites = [s for s in suites if s["rc"] not in ("0", "NOT_RUN")
                  and s["name"] != "setup" and not any(r.suite == s["name"] and failed(r) for r in results)]
    if suite_errors or bad_suites:
        T.append("## Suite-level errors\n")
        for n, e in suite_errors[:40]:
            T.append(f"- {n}: `{e}`")
        for s in bad_suites:
            tail = [l for _, l in lines_of(os.path.join(out, "suites", s["name"] + ".log"))][-30:]
            T.append(f"\n{s['name']} exited {s['rc']} with no failed file recorded; last lines:\n")
            T.append("```\n" + "\n".join(tail) + "\n```")
        T.append("")

    skips = [r for r in results if r.result == "SKIP"]
    if skips:
        T.append(f"## Skipped ({len(skips)})\n")
        for r in skips:
            T.append(f"- {r.suite} · {r.conf} · `{r.file}`" + (f" — {r.notes}" if r.notes else ""))
        T.append("")

    T.append("## Every file\n")
    for s in suites:
        rs = [r for r in results if r.suite == s["name"]]
        if not rs:
            continue
        T.append(f"### {SUITE_TITLE.get(s['name'], s['name'])}\n")
        T.append("| conf | file | result | time |")
        T.append("|---|---|---|---|")
        for r in rs:
            T.append(f"| {r.conf} | `{r.file}` | {r.result} | {dur(r.seconds)} |")
        T.append("")
    with open(os.path.join(out, "test_report.md"), "w") as f:
        f.write("\n".join(T) + "\n")

    # ---------------------------------------------------- performance
    host = tsv(out, "host.tsv")
    groups = tsv(out, "groups.tsv")
    nh = tsv(out, "net_host.tsv")
    sn = tsv(out, "server_net.tsv")
    phone = tsv(out, "phone.tsv")
    pprocs = tsv(out, "phone_procs.tsv")
    nphone = tsv(out, "net_phone.tsv")
    reqs = server_requests(out)
    interval = None
    if len(host) > 2:
        interval = (epoch(host[-1]["ts"]) - epoch(host[0]["ts"])) / (len(host) - 1)

    P = ["# Full regression — performance log\n"]
    P += [f"- {m}" for m in meta]
    P.append(f"- samples: {len(host)} host, {len(phone)} phone"
             + (f", every ~{interval:.0f} s" if interval else ""))
    errs = file_lines(os.path.join(out, "metrics", "sampler_errors.log"))
    P.append(f"- sampler errors: {len(errs)}" + (" (see metrics/sampler_errors.log)" if errs else ""))
    P.append("- CPU of a process group is in % of one core (200 = two cores busy); host CPU is % of all cores.\n")

    P.append("## Time taken\n")
    P.append("| suite | wall time | files | mean per file | slowest file | stack start (mean / max) |")
    P.append("|---|---|---|---|---|---|")
    for s in suites:
        rs = [r for r in results if r.suite == s["name"] and r.seconds]
        st = stacks.get(s["name"], [])
        slow = max(rs, key=lambda r: r.seconds) if rs else None
        P.append(f"| {s['name']} | {dur(s['end'] - s['start'])} | {len(rs) or '–'} | "
                 f"{dur(statistics.mean(r.seconds for r in rs)) if rs else '–'} | "
                 f"{f'`{os.path.basename(slow.file)}` ({slow.conf}) {dur(slow.seconds)}' if slow else '–'} | "
                 f"{f'{dur(statistics.mean(st))} / {dur(max(st))} ({len(st)} stacks)' if st else '–'} |")
    P.append("")
    timed = sorted([r for r in results if r.seconds and r.suite in INTEGRATION], key=lambda r: -r.seconds)[:15]
    if timed:
        P.append("Slowest integration files:\n")
        P.append("| suite | conf | file | time | result |")
        P.append("|---|---|---|---|---|")
        for r in timed:
            P.append(f"| {r.suite} | {r.conf} | `{os.path.basename(r.file)}` | {dur(r.seconds)} | {r.result} |")
        P.append("")
    by_conf = collections.defaultdict(float)
    for r in results:
        if r.seconds and r.suite in INTEGRATION:
            by_conf[(r.suite, r.conf)] += r.seconds
    if by_conf:
        P.append("Time per suite and server conf (sum of file times): "
                 + ", ".join(f"{s}/{c} {dur(v)}" for (s, c), v in sorted(by_conf.items())) + "\n")

    phases = [s["name"] for s in suites if s["rc"] != "NOT_RUN"]
    if any(r["phase"] == "retry" for r in host):
        phases.append("retry")

    P.append("## Host (the laptop: test runner, server and, for the Linux suites, the device)\n")
    P.append("| phase | CPU % mean / p95 / max | load max | mem used max | mem avail min | swap max | disk read | disk write |")
    P.append("|---|---|---|---|---|---|---|---|")
    for ph in phases:
        rows = [r for r in host if r["phase"] == ph]
        if not rows:
            P.append(f"| {ph} | no samples | | | | | | |")
            continue
        dt = interval or 15
        P.append(f"| {ph} | {' / '.join(stats(nums(rows, 'cpu_pct')))} | {max(nums(rows, 'load1')):.1f} | "
                 f"{max(nums(rows, 'mem_used_mb')):,.0f} MB | {min(nums(rows, 'mem_avail_mb')):,.0f} MB | "
                 f"{max(nums(rows, 'swap_used_mb')):,.0f} MB | {mb(sum(nums(rows, 'disk_read_mb_s')) * dt * 1e6)} | "
                 f"{mb(sum(nums(rows, 'disk_write_mb_s')) * dt * 1e6)} |")
    P.append("")

    P.append("## Server and processes\n")
    P.append("server_api is uvicorn, server_db is postgres (all its backends); app_linux is the app under test "
             "on the desktop; flutter_tool is the build and test tooling.\n")
    P.append("| phase | group | CPU % (1 core) mean / p95 / max | RSS max |")
    P.append("|---|---|---|---|")
    for ph in phases:
        rows = [r for r in groups if r["phase"] == ph]
        for g in sorted({r["group"] for r in rows}):
            gr = [r for r in rows if r["group"] == g]
            P.append(f"| {ph} | {g} | {' / '.join(stats(nums(gr, 'cpu_core_pct')))} | {max(nums(gr, 'rss_mb')):,.0f} MB |")
    P.append("")

    P.append("### API requests (from the server logs)\n")
    if not reqs:
        P.append("No server log was captured.\n")
    for ph, d in sorted(reqs.items()):
        P.append(f"**{ph}** — {d['logs']} stack log(s), {d['n']:,} requests, "
                 + ", ".join(f"{k} {v:,}" for k, v in sorted(d["status"].items()))
                 + f", tracebacks {d['tb']}")
        if d["unmatched"]:
            P.append(f"  ({d['unmatched']} log(s) had no access lines this report recognises)")
        if d["5xx"]:
            P.append("  5xx: " + "; ".join(f"{k} ×{v}" for k, v in d["5xx"].most_common(10)))
        if d["ep"]:
            P.append("  busiest: " + "; ".join(f"`{k}` {v:,}" for k, v in d["ep"].most_common(8)))
        P.append("")

    P.append("## Phone\n")
    if not phone:
        P.append("No phone samples (no phone suite ran, or the phone was not attached).\n")
    else:
        P.append("| phase | CPU % mean / p95 / max | mem avail min | battery start → end | temp max |")
        P.append("|---|---|---|---|---|")
        for ph in phases:
            rows = [r for r in phone if r["phase"] == ph]
            if not rows:
                continue
            lv = nums(rows, "battery_level")
            tp = nums(rows, "battery_temp_c")
            ma = nums(rows, "mem_avail_mb")
            P.append(f"| {ph} | {' / '.join(stats(nums(rows, 'cpu_pct')))} | {f'{min(ma):,.0f} MB' if ma else '–'} | "
                     f"{f'{lv[0]:.0f}% → {lv[-1]:.0f}%' if lv else '–'} | {f'{max(tp):.1f} °C' if tp else '–'} |")
        P.append("")
        P.append("Processes on the phone (top's %CPU, of one core):\n")
        P.append("| phase | process | CPU % mean / max | RSS max |")
        P.append("|---|---|---|---|")
        for ph in phases:
            rows = [r for r in pprocs if r["phase"] == ph]
            for name in sorted({r["name"] for r in rows}):
                pr = [r for r in rows if r["name"] == name]
                c = nums(pr, "cpu_pct")
                rss = nums(pr, "rss_mb")
                P.append(f"| {ph} | {name} | {stats(c)[0]} / {stats(c)[2]} | {f'{max(rss):,.0f} MB' if rss else '–'} |")
        P.append("")

    P.append("## Network\n")
    P.append("- API server sockets: bytes the server sent / received, read from `ss` each sample; "
             "connections that opened and closed between samples are missed, so this is a lower bound.")
    P.append("- Host interfaces: `lo` carries the app ↔ server traffic of the Linux suites and the adb / "
             "ChromeDriver traffic; the others are the internet (git clone, pub get, uv sync, ChromeDriver download).")
    P.append("- Phone interfaces: the app reaches the server through `adb reverse`, which shows on the phone's `lo`.\n")
    P.append("| phase | server sent | server received | host interfaces (rx / tx) | phone interfaces (rx / tx) |")
    P.append("|---|---|---|---|---|")
    for ph in phases:
        s_tot = counter_delta([r for r in sn if r["phase"] == ph], "port")
        tx = sum(v[1] for v in s_tot.values())
        rx = sum(v[0] for v in s_tot.values())
        h = counter_delta([r for r in nh if r["phase"] == ph], "iface")
        p = counter_delta([r for r in nphone if r["phase"] == ph], "iface")
        fmt = lambda t: ", ".join(f"{k} {mb(v[0])} / {mb(v[1])}" for k, v in sorted(t.items()) if v[0] + v[1] > 1e4) or "–"
        P.append(f"| {ph} | {mb(tx)} | {mb(rx)} | {fmt(h)} | {fmt(p)} |")
    P.append("")
    P.append("Raw samples: `metrics/*.tsv`; server logs: `server_logs/`.")
    with open(os.path.join(out, "performance_log.md"), "w") as f:
        f.write("\n".join(P) + "\n")
    print(f"wrote {out}/test_report.md, {out}/performance_log.md ({len(results)} results, {len(fails)} failures)")


def print_failures(out):
    _, results, _, _ = collect(out)
    for r in results:
        if failed(r) and r.suite in INTEGRATION and r.conf not in ("?", "-"):
            print(f"{r.suite}\t{r.conf}\t{os.path.basename(r.file)}")


if __name__ == "__main__":
    if len(sys.argv) != 3 or sys.argv[1] not in ("report", "failures"):
        print(__doc__)
        sys.exit(2)
    (write_reports if sys.argv[1] == "report" else print_failures)(sys.argv[2])

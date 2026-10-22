#!/usr/bin/env python3
"""Sample host, test-stack, app and phone metrics while the regression runs.

    sampler.py <out_dir> <worktree> [interval_seconds] [phone_every_n]

Every interval (default 15 s) it appends rows to <out_dir>/metrics/*.tsv, each
tagged with the phase named in <out_dir>/phase (the suite running). It stops
when <out_dir>/stop exists. Started and stopped by run_full_regression.sh.

  host.tsv        whole-machine CPU, load, memory, swap, disk throughput
  groups.tsv      CPU and memory of process groups: server_api (uvicorn),
                  server_db (postgres), app_linux (the app under test on the
                  desktop), flutter_tool, chromedriver, adb
  net_host.tsv    cumulative bytes per host network interface
  server_net.tsv  bytes the API server sent and received on its sockets
                  (sampled from `ss`, so a connection opened and closed
                  between two samples is missed: a lower bound)
  phone.tsv       phone CPU, free memory, battery level and temperature
  phone_procs.tsv CPU and memory of Chrome and the test app on the phone
  net_phone.tsv   cumulative bytes per phone network interface
  server_logs.tsv which server log was first seen in which phase

Each stack's server.log is copied as it grows into <out_dir>/server_logs/,
from a handle held open, so the lines written just before the stack's
teardown deletes it are kept. Errors go to metrics/sampler_errors.log
and never stop sampling.
"""
import glob
import os
import re
import subprocess
import sys
import time
import traceback

OUT = sys.argv[1]
WT = sys.argv[2]
INTERVAL = float(sys.argv[3]) if len(sys.argv) > 3 else 15.0
PHONE_EVERY = int(sys.argv[4]) if len(sys.argv) > 4 else 2
ADB = os.environ.get("ADB", "adb")
APP_PACKAGE = os.environ.get("APP_PACKAGE", "com.example.cl_club_app_example")
TCK = os.sysconf("SC_CLK_TCK")
PAGE = os.sysconf("SC_PAGE_SIZE")
NCPU = os.cpu_count() or 1
MET = os.path.join(OUT, "metrics")
LOGS = os.path.join(OUT, "server_logs")
os.makedirs(MET, exist_ok=True)
os.makedirs(LOGS, exist_ok=True)
DEPLOYED = "/.native_deploy/deployed/"

HEADERS = {
    "host.tsv": "ts\tphase\tcpu_pct\tload1\tmem_used_mb\tmem_avail_mb\tswap_used_mb\tdisk_read_mb_s\tdisk_write_mb_s",
    "groups.tsv": "ts\tphase\tgroup\tcpu_core_pct\trss_mb\tnprocs",
    "net_host.tsv": "ts\tphase\tiface\trx_bytes\ttx_bytes",
    "server_net.tsv": "ts\tphase\tport\tconns\ttx_bytes_total\trx_bytes_total",
    "phone.tsv": "ts\tphase\tcpu_pct\tmem_avail_mb\tbattery_level\tbattery_temp_c",
    "phone_procs.tsv": "ts\tphase\tname\tcpu_pct\trss_mb",
    "net_phone.tsv": "ts\tphase\tiface\trx_bytes\ttx_bytes",
    "server_logs.tsv": "ts\tphase\tsource\tcopy",
}
FILES = {}
for name, header in HEADERS.items():
    path = os.path.join(MET, name)
    new = not os.path.exists(path)
    FILES[name] = open(path, "a", buffering=1)
    if new:
        FILES[name].write(header + "\n")
ERR = open(os.path.join(MET, "sampler_errors.log"), "a", buffering=1)


def row(name, *vals):
    FILES[name].write("\t".join(str(v) for v in vals) + "\n")


def err(msg):
    ERR.write(time.strftime("%F %T ") + msg + "\n")


def read(path, mode="r"):
    try:
        with open(path, mode) as f:
            return f.read()
    except OSError:
        return None


def phase():
    return (read(os.path.join(OUT, "phase")) or "idle").strip() or "idle"


def parse_netdev(text):
    out = {}
    for line in (text or "").splitlines()[2:]:
        if ":" not in line:
            continue
        iface, rest = line.split(":", 1)
        f = rest.split()
        if len(f) >= 9:
            out[iface.strip()] = (int(f[0]), int(f[8]))
    return out


def cpu_times(stat_text):
    f = [int(x) for x in stat_text.splitlines()[0].split()[1:9]]
    return sum(f), f[3] + f[4]


# ---------------------------------------------------------------- host

prev_cpu = None
prev_disk = None
prev_t = None


def sample_host(ts, ph):
    global prev_cpu, prev_disk, prev_t
    now = time.time()
    total, idle = cpu_times(read("/proc/stat"))
    mem = {}
    for line in read("/proc/meminfo").splitlines():
        k, v = line.split(":", 1)
        mem[k] = int(v.split()[0])
    rd = wr = 0
    for line in read("/proc/diskstats").splitlines():
        f = line.split()
        if re.fullmatch(r"sd[a-z]+|nvme\d+n\d+|vd[a-z]+", f[2]):
            rd += int(f[5]) * 512
            wr += int(f[9]) * 512
    load1 = read("/proc/loadavg").split()[0]
    if prev_cpu is not None:
        dt = now - prev_t
        dtot = total - prev_cpu[0]
        cpu = 100.0 * (1 - (idle - prev_cpu[1]) / dtot) if dtot > 0 else 0.0
        row("host.tsv", ts, ph, f"{cpu:.1f}", load1,
            (mem["MemTotal"] - mem["MemAvailable"]) // 1024, mem["MemAvailable"] // 1024,
            (mem["SwapTotal"] - mem["SwapFree"]) // 1024,
            f"{(rd - prev_disk[0]) / dt / 1e6:.2f}", f"{(wr - prev_disk[1]) / dt / 1e6:.2f}")
    prev_cpu, prev_disk, prev_t = (total, idle), (rd, wr), now
    for iface, (rx, tx) in parse_netdev(read("/proc/net/dev")).items():
        row("net_host.tsv", ts, ph, iface, rx, tx)


# ---------------------------------------------------------------- processes

prev_jiffies = {}  # pid -> (starttime, jiffies)
prev_proc_t = None


def own_class(cmd, exe, cwd):
    in_stack = DEPLOYED in cmd or DEPLOYED in exe or DEPLOYED in cwd
    if in_stack and "uvicorn" in cmd:
        return "server_api"
    if in_stack and ("postgres" in cmd or "postgres" in exe):
        return "server_db"
    if "/build/linux/" in exe:
        return "app_linux"
    if "chromedriver" in cmd:
        return "chromedriver"
    if "flutter_tools.snapshot" in cmd or "frontend_server" in cmd:
        return "flutter_tool"
    if os.path.basename(exe) == "adb" or cmd.startswith("adb "):
        return "adb"
    return None


def sample_procs(ts, ph):
    global prev_proc_t
    now = time.time()
    procs = {}
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        stat = read(f"/proc/{pid}/stat")
        if not stat:
            continue
        f = stat[stat.rfind(")") + 2:].split()
        cmd = (read(f"/proc/{pid}/cmdline") or "").replace("\0", " ").strip()
        try:
            exe = os.readlink(f"/proc/{pid}/exe")
        except OSError:
            exe = ""
        try:
            cwd = os.readlink(f"/proc/{pid}/cwd")
        except OSError:
            cwd = ""
        procs[int(pid)] = {
            "ppid": int(f[1]), "jiffies": int(f[11]) + int(f[12]),
            "start": int(f[19]), "rss": int(f[21]) * PAGE,
            "cls": own_class(cmd, exe, cwd), "cmd": cmd,
        }

    def resolve(pid, depth=0):
        p = procs.get(pid)
        if p is None or depth > 64:
            return None
        if p["cls"] is None and p["ppid"] > 1:
            return resolve(p["ppid"], depth + 1)
        return p["cls"]

    groups = {}
    dt = (now - prev_proc_t) if prev_proc_t else None
    new_prev = {}
    for pid, p in procs.items():
        cls = resolve(pid)
        new_prev[pid] = (p["start"], p["jiffies"])
        if cls is None:
            continue
        g = groups.setdefault(cls, [0.0, 0, 0])
        before = prev_jiffies.get(pid)
        used = p["jiffies"] - before[1] if before and before[0] == p["start"] else p["jiffies"]
        if dt:
            g[0] += 100.0 * used / TCK / dt
        g[1] += p["rss"]
        g[2] += 1
    prev_jiffies.clear()
    prev_jiffies.update(new_prev)
    prev_proc_t = now
    if dt:
        for cls, (cpu, rss, n) in sorted(groups.items()):
            row("groups.tsv", ts, ph, cls, f"{cpu:.1f}", rss // (1 << 20), n)
    return [p for p in procs.values() if p["cls"] == "server_api"]


# ---------------------------------------------------------------- server sockets and logs

sock_max = {}      # (port, peer) -> [tx, rx]
closed = {}        # port -> [tx, rx]


def sample_server_net(ts, ph, api_procs):
    ports = set()
    for p in api_procs:
        m = re.search(r"--port[ =](\d+)", p["cmd"])
        if m:
            ports.add(m.group(1))
    for port in sorted(ports):
        try:
            out = subprocess.run(["ss", "-tinH", "state", "established", f"( sport = :{port} )"],
                                 capture_output=True, text=True, timeout=10)
        except (OSError, subprocess.TimeoutExpired) as e:
            err(f"ss {port}: {e}")
            continue
        if out.returncode != 0:
            err(f"ss {port}: rc={out.returncode} {out.stderr.strip()}")
            continue
        seen = {}
        peer = None
        for line in out.stdout.splitlines():
            if line and not line[0].isspace():
                f = line.split()
                peer = f[-1] if len(f) >= 4 else None
            elif peer:
                tx = re.search(r"bytes_acked:(\d+)", line)
                rx = re.search(r"bytes_received:(\d+)", line)
                seen[(port, peer)] = [int(tx.group(1)) if tx else 0, int(rx.group(1)) if rx else 0]
                peer = None
        for key in [k for k in sock_max if k[0] == port and k not in seen]:
            c = closed.setdefault(port, [0, 0])
            c[0] += sock_max[key][0]
            c[1] += sock_max[key][1]
            del sock_max[key]
        for key, (tx, rx) in seen.items():
            m = sock_max.setdefault(key, [0, 0])
            m[0], m[1] = max(m[0], tx), max(m[1], rx)
        c = closed.get(port, [0, 0])
        open_tx = sum(v[0] for k, v in sock_max.items() if k[0] == port)
        open_rx = sum(v[1] for k, v in sock_max.items() if k[0] == port)
        row("server_net.tsv", ts, ph, port, len(seen), c[0] + open_tx, c[1] + open_rx)


log_handles = {}   # (path, inode) -> [source file, dest path]


def copy_server_logs(ts, ph):
    """Copy each stack's server.log as it grows. The source stays open, so
    whatever is written up to the stack's teardown is still read after the
    teardown deletes the file."""
    for path in glob.glob(os.path.join(WT, ".native_deploy", "deployed", "*", "server.log")):
        try:
            st = os.stat(path)
        except OSError:
            continue
        key = (path, st.st_ino)
        if key in log_handles:
            continue
        try:
            src = open(path, "rb")
        except OSError as e:
            err(f"open {path}: {e}")
            continue
        dest = os.path.join(LOGS, f"{time.strftime('%Y%m%d-%H%M%S')}-{os.path.basename(os.path.dirname(path))}.log")
        log_handles[key] = [src, dest]
        row("server_logs.tsv", ts, ph, path, dest)
    for key, (src, dest) in list(log_handles.items()):
        data = src.read()
        if data:
            with open(dest, "ab") as dst:
                dst.write(data)
        elif os.fstat(src.fileno()).st_nlink == 0:   # deleted and fully read
            src.close()
            del log_handles[key]


# ---------------------------------------------------------------- phone

prev_phone_cpu = None

PHONE_CMD = (
    "head -1 /proc/stat; echo @@; grep -E 'MemTotal|MemAvailable' /proc/meminfo; echo @@; "
    "dumpsys battery; echo @@; cat /proc/net/dev; echo @@; "
    "top -b -n 1 -o PID,%CPU,RES,NAME | grep -E 'chrome|" + APP_PACKAGE.replace(".", "\\.") + "|adbd'"
)


def size_mb(s):
    m = re.fullmatch(r"([\d.]+)([KMGT]?)", s)
    if not m:
        return ""
    v = float(m.group(1))
    return int(v * {"": 1 / 1024, "K": 1 / 1024, "M": 1, "G": 1024, "T": 1 << 20}[m.group(2)])


def sample_phone(ts, ph):
    global prev_phone_cpu
    try:
        state = subprocess.run([ADB, "get-state"], capture_output=True, text=True, timeout=10)
        if state.stdout.strip() != "device":
            return
        out = subprocess.run([ADB, "shell", PHONE_CMD], capture_output=True, text=True, timeout=30)
    except (OSError, subprocess.TimeoutExpired) as e:
        err(f"adb: {e}")
        return
    parts = out.stdout.split("@@")
    if len(parts) < 5:
        err(f"adb shell gave {len(parts)} parts: rc={out.returncode} {out.stderr.strip()[:200]}")
        return
    total, idle = cpu_times(parts[0].strip())
    cpu = ""
    if prev_phone_cpu and total > prev_phone_cpu[0]:
        cpu = f"{100.0 * (1 - (idle - prev_phone_cpu[1]) / (total - prev_phone_cpu[0])):.1f}"
    prev_phone_cpu = (total, idle)
    avail = re.search(r"MemAvailable:\s+(\d+)", parts[1])
    level = re.search(r"^\s*level:\s*(\d+)", parts[2], re.M)
    temp = re.search(r"^\s*temperature:\s*(\d+)", parts[2], re.M)
    row("phone.tsv", ts, ph, cpu, int(avail.group(1)) // 1024 if avail else "",
        level.group(1) if level else "", f"{int(temp.group(1)) / 10:.1f}" if temp else "")
    for iface, (rx, tx) in parse_netdev(parts[3].strip("\n")).items():
        row("net_phone.tsv", ts, ph, iface, rx, tx)
    for line in parts[4].strip().splitlines():
        f = line.split()
        if len(f) >= 4:
            row("phone_procs.tsv", ts, ph, f[3], f[1], size_mb(f[2]))


# ---------------------------------------------------------------- loop

def main():
    n = 0
    while not os.path.exists(os.path.join(OUT, "stop")):
        start = time.time()
        ts = time.strftime("%Y-%m-%d %H:%M:%S")
        ph = phase()
        for name, fn in (("host", lambda: sample_host(ts, ph)),
                         ("logs", lambda: copy_server_logs(ts, ph))):
            try:
                fn()
            except Exception:
                err(f"{name}: {traceback.format_exc()}")
        try:
            api = sample_procs(ts, ph)
            sample_server_net(ts, ph, api)
        except Exception:
            err(f"procs: {traceback.format_exc()}")
        if n % PHONE_EVERY == 0:
            try:
                sample_phone(ts, ph)
            except Exception:
                err(f"phone: {traceback.format_exc()}")
        n += 1
        while time.time() - start < INTERVAL and not os.path.exists(os.path.join(OUT, "stop")):
            time.sleep(1)
            try:
                copy_server_logs(time.strftime("%Y-%m-%d %H:%M:%S"), phase())
            except Exception:
                err(f"logs: {traceback.format_exc()}")
    copy_server_logs(time.strftime("%Y-%m-%d %H:%M:%S"), phase())


if __name__ == "__main__":
    main()

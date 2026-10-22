#!/usr/bin/env python3
"""Keep the clipboard permissions granted to the test page in Chrome on the phone.

    scripts/phone_chrome_grant.py <devtools_port> <origin> [interval_seconds]

Run by scripts/phone_web_test.sh while the files run (#288). The phone's
Chrome DevTools socket must be forwarded to <devtools_port> on this machine
(`adb forward tcp:<port> localabstract:chrome_devtools_remote`).

ChromeDriver starts Chrome afresh for each file, and a permission granted
through DevTools lasts only as long as that Chrome, so this grants
clipboardReadWrite and clipboardSanitizedWrite to <origin> every interval
(default 2 s) until it is killed. Without it, reading the clipboard makes
Chrome ask, and an unattended run waits on that prompt.

It prints one line each time the outcome changes (granted, or why not), so
the log shows when Chrome came and went without a line every interval.
"""
import base64
import json
import os
import socket
import struct
import sys
import time
import urllib.request

PORT = int(sys.argv[1])
ORIGIN = sys.argv[2]
INTERVAL = float(sys.argv[3]) if len(sys.argv) > 3 else 2.0
PERMISSIONS = ["clipboardReadWrite", "clipboardSanitizedWrite"]


def browser_ws_path():
    with urllib.request.urlopen(f"http://127.0.0.1:{PORT}/json/version", timeout=5) as r:
        url = json.load(r)["webSocketDebuggerUrl"]
    # ws://<host>/<path>: the host Chrome reports is its own, not the forwarded port.
    return "/" + url.split("://", 1)[1].split("/", 1)[1]


def recv_exact(sock, n):
    buf = b""
    while len(buf) < n:
        chunk = sock.recv(n - len(buf))
        if not chunk:
            raise ConnectionError("socket closed")
        buf += chunk
    return buf


def ws_call(path, message):
    """One request over a fresh WebSocket; returns the reply with the same id."""
    sock = socket.create_connection(("127.0.0.1", PORT), timeout=10)
    try:
        key = base64.b64encode(os.urandom(16)).decode()
        sock.sendall((f"GET {path} HTTP/1.1\r\nHost: 127.0.0.1:{PORT}\r\n"
                      "Upgrade: websocket\r\nConnection: Upgrade\r\n"
                      f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n").encode())
        head = b""
        while b"\r\n\r\n" not in head:
            chunk = sock.recv(1024)
            if not chunk:
                raise ConnectionError("closed during handshake")
            head += chunk
        if b" 101 " not in head.split(b"\r\n", 1)[0]:
            raise ConnectionError(head.split(b"\r\n", 1)[0].decode(errors="replace"))
        payload = json.dumps(message).encode()
        mask = os.urandom(4)
        n = len(payload)
        header = bytes([0x81]) + (bytes([0x80 | n]) if n < 126 else bytes([0x80 | 126]) + struct.pack(">H", n))
        sock.sendall(header + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(payload)))
        while True:
            b1, b2 = recv_exact(sock, 2)
            ln = b2 & 0x7F
            if ln == 126:
                ln = struct.unpack(">H", recv_exact(sock, 2))[0]
            elif ln == 127:
                ln = struct.unpack(">Q", recv_exact(sock, 8))[0]
            data = recv_exact(sock, ln)
            if b1 & 0x0F == 0x8:
                raise ConnectionError("closed by Chrome")
            if b1 & 0x0F == 0x1:
                reply = json.loads(data)
                if reply.get("id") == message["id"]:
                    return reply
    finally:
        sock.close()


def main():
    last = None
    n = 0
    while True:
        n += 1
        try:
            reply = ws_call(browser_ws_path(), {
                "id": n, "method": "Browser.grantPermissions",
                "params": {"origin": ORIGIN, "permissions": PERMISSIONS}})
            outcome = f"error: {reply['error'].get('message')}" if "error" in reply else "granted"
        except Exception as e:  # Chrome not running yet, between files, or gone
            outcome = f"no Chrome to grant to ({type(e).__name__}: {e})"
        if outcome != last:
            print(time.strftime("%H:%M:%S"), f"{' + '.join(PERMISSIONS)} for {ORIGIN}: {outcome}", flush=True)
            last = outcome
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()

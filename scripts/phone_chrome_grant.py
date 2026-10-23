#!/usr/bin/env python3
"""Keep the clipboard permissions granted to the test page in Chrome on the phone.

    scripts/phone_chrome_grant.py <devtools_port> <origin> [interval_seconds]

Run by scripts/phone_web_test.sh while the files run (#288). The phone's
Chrome DevTools socket must be forwarded to <devtools_port> on this machine
(`adb forward tcp:<port> localabstract:chrome_devtools_remote`).

Chrome keeps a permission granted through DevTools only while the DevTools
connection that granted it stays open: once it closes, the page is back to
asking. So this connects to Chrome, grants clipboardReadWrite and
clipboardSanitizedWrite to <origin>, and holds that connection open. When
Chrome goes (ChromeDriver starts it afresh for each file), the connection
drops; it then tries again every interval (default 2 s) until the next
Chrome is up, and grants to it the same way. It runs until it is killed.

Without it, reading the clipboard makes Chrome ask, and an unattended run
waits on that prompt.

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


def connect(path):
    """A WebSocket to Chrome's browser endpoint at [path]."""
    sock = socket.create_connection(("127.0.0.1", PORT), timeout=10)
    key = base64.b64encode(os.urandom(16)).decode()
    sock.sendall((f"GET {path} HTTP/1.1\r\nHost: 127.0.0.1:{PORT}\r\n"
                  "Upgrade: websocket\r\nConnection: Upgrade\r\n"
                  f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n").encode())
    head = b""
    while b"\r\n\r\n" not in head:
        chunk = sock.recv(1024)
        if not chunk:
            sock.close()
            raise ConnectionError("closed during handshake")
        head += chunk
    if b" 101 " not in head.split(b"\r\n", 1)[0]:
        sock.close()
        raise ConnectionError(head.split(b"\r\n", 1)[0].decode(errors="replace"))
    return sock


def send(sock, message):
    payload = json.dumps(message).encode()
    mask = os.urandom(4)
    n = len(payload)
    header = bytes([0x81]) + (bytes([0x80 | n]) if n < 126 else bytes([0x80 | 126]) + struct.pack(">H", n))
    sock.sendall(header + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(payload)))


def next_frame(sock):
    """(opcode, data) of the next frame; raises once the connection closes."""
    b1, b2 = recv_exact(sock, 2)
    ln = b2 & 0x7F
    if ln == 126:
        ln = struct.unpack(">H", recv_exact(sock, 2))[0]
    elif ln == 127:
        ln = struct.unpack(">Q", recv_exact(sock, 8))[0]
    data = recv_exact(sock, ln)
    if b1 & 0x0F == 0x8:
        raise ConnectionError("closed by Chrome")
    return b1 & 0x0F, data


def reply(sock, message_id):
    """Chrome's answer to the request [message_id]."""
    while True:
        opcode, data = next_frame(sock)
        if opcode == 0x1:
            answer = json.loads(data)
            if answer.get("id") == message_id:
                return answer


def grant_and_hold():
    """Grants to the Chrome that is up now, holds the grant while that
    Chrome runs, and returns once it has gone (by raising) or refused."""
    sock = connect(browser_ws_path())
    try:
        send(sock, {"id": 1, "method": "Browser.grantPermissions",
                    "params": {"origin": ORIGIN, "permissions": PERMISSIONS}})
        answer = reply(sock, 1)
        if "error" in answer:
            return f"error: {answer['error'].get('message')}"
        log("granted; holding the DevTools connection open")
        # The grant lasts while this connection does: wait here until Chrome
        # closes it. Anything Chrome sends meanwhile is read and dropped.
        sock.settimeout(None)
        while True:
            next_frame(sock)
    finally:
        sock.close()


_last = None


def log(outcome):
    global _last
    if outcome != _last:
        print(time.strftime("%H:%M:%S"), f"{' + '.join(PERMISSIONS)} for {ORIGIN}: {outcome}", flush=True)
        _last = outcome


def main():
    while True:
        try:
            outcome = grant_and_hold()
        except Exception as e:  # Chrome not running yet, between files, or gone
            outcome = f"no Chrome to grant to ({type(e).__name__}: {e})"
        log(outcome)
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()

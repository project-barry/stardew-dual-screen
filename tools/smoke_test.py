#!/usr/bin/env python3
"""Talks to a Stardew Valley Dual Screen Mod socket (or tools/fake_stardew.py)
as the app does: waits for the day and the bag, selects a hotbar slot and
checks that the game says it is selected. For CI, against the stand-in.

  python3 tools/smoke_test.py [--port 7786]
"""
import argparse
import base64
import json
import os
import socket
import struct
import sys
import time


def send(sock, text):
    body = text.encode()
    mask = os.urandom(4)
    n = len(body)
    head = bytes([0x81, 0x80 | n]) if n < 126 else bytes([0x81, 0x80 | 126]) + struct.pack(">H", n)
    sock.sendall(head + mask + bytes(c ^ mask[i % 4] for i, c in enumerate(body)))


def recv(sock, buf):
    while True:
        if len(buf) >= 2:
            n, at = buf[1] & 0x7F, 2
            if n == 126 and len(buf) >= 4:
                n, at = struct.unpack(">H", buf[2:4])[0], 4
            elif n == 127 and len(buf) >= 10:
                n, at = struct.unpack(">Q", buf[2:10])[0], 10
            if n < 126 or at > 2:
                if len(buf) >= at + n:
                    return buf[at:at + n].decode(), buf[at + n:]
        got = sock.recv(65536)
        if not got:
            raise ConnectionError("closed")
        buf += got


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--port", type=int, default=7786)
    args = p.parse_args()
    sock = socket.create_connection(("127.0.0.1", args.port), timeout=10)
    key = base64.b64encode(os.urandom(16)).decode()
    sock.sendall(("GET / HTTP/1.1\r\nHost: 127.0.0.1\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
                  "Sec-WebSocket-Key: %s\r\nSec-WebSocket-Version: 13\r\n\r\n" % key).encode())
    buf = b""
    while b"\r\n\r\n" not in buf:
        buf += sock.recv(4096)
    head, buf = buf.split(b"\r\n\r\n", 1)
    assert b" 101 " in head.split(b"\r\n")[0], head
    seen = {}
    sprites = 0
    deadline = time.time() + 10
    sent = False
    while time.time() < deadline:
        text, buf = recv(sock, buf)
        m = json.loads(text)
        if m["type"] == "sdv_sprite":
            sprites += 1
            continue
        seen[m["type"]] = m
        if not sent and "sdv_day" in seen and "sdv_inventory" in seen:
            send(sock, json.dumps({"type": "select_slot", "slot": 4}))
            sent = True
        elif sent and m["type"] == "sdv_inventory" and m["selected"] == 4:
            print("OK: %d kinds of message, %d pictures, select_slot answered" % (len(seen), sprites))
            return 0
    print("FAILED: saw", sorted(seen), file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""
Relay server for remote Claude Code hook events.

Usage:
  python3 relay.py          # foreground
  python3 relay.py &        # background
  python3 relay.py --kill   # stop running server

Remote sessions send: curl http://127.0.0.1:19876/<event>

Environment:
  CLAUDE_SOUND_PORT    - server port (default: 19876)
  CLAUDE_SOUND_VOLUME  - volume 0-100 (default: 60)
"""
import http.server
import subprocess
import os
import re
import sys
import signal
import random
import time
import socketserver

PORT = int(os.environ.get("CLAUDE_SOUND_PORT", 19876))
VOLUME = int(os.environ.get("CLAUDE_SOUND_VOLUME", 60))
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(BASE_DIR, "..", "assets", "trek")
PID_FILE = os.path.join(BASE_DIR, ".relay.pid")

VALID_EVENT = re.compile(r"^[a-zA-Z0-9_]+$")

# Volume scale for high-frequency events
EVENT_VOLUME_SCALE = {
    "subagent_start": 0.7,
    "subagent_stop": 0.7,
}

# Map events to Trek sound files (remote mode uses Trek only)
EVENT_MAP = {
    "start":          ["TrekChirp.mp3"],
    "submit":         ["TrekBeep1.mp3", "TrekBeep5.mp3"],
    "what":           ["TrekHail.mp3", "TrekAlertUser.mp3"],
    "complete":       ["TrekProgramComplete.mp3", "TrekDataTransmitted.mp3"],
    "error":          ["TrekBeep55.mp3", "TrekRedAlert.mp3"],
    "beep":           ["TrekBeep1.mp3", "TrekBeep5.mp3", "TrekBeep10.mp3"],
    "subagent_start": ["TrekTransporter.mp3"],
    "subagent_stop":  ["TrekWorking.mp3", "TrekBeep10.mp3"],
    "precompact":     ["TrekRedAlert.mp3"],
    "session_end":    ["TrekChirp.mp3"],
}


def play_sound(event: str):
    if not VALID_EVENT.match(event):
        return
    patterns = EVENT_MAP.get(event, [])
    if not patterns:
        return
    candidates = [
        os.path.join(ASSETS_DIR, p)
        for p in patterns
        if os.path.exists(os.path.join(ASSETS_DIR, p))
    ]
    if not candidates:
        return

    scale = EVENT_VOLUME_SCALE.get(event, 1.0)
    vol = (VOLUME / 100.0) * scale

    subprocess.Popen(
        ["afplay", "-v", f"{vol:.2f}", random.choice(candidates)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


class SoundHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        event = self.path.strip("/")
        if event:
            play_sound(event)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, format, *args):
        pass


class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True


def kill_existing():
    if not os.path.exists(PID_FILE):
        return
    try:
        with open(PID_FILE) as f:
            pid = int(f.read().strip())
        os.kill(pid, signal.SIGTERM)
        for _ in range(20):
            try:
                os.kill(pid, 0)
                time.sleep(0.1)
            except ProcessLookupError:
                break
        print(f"Stopped relay (PID {pid})")
    except (ProcessLookupError, ValueError):
        pass
    try:
        os.remove(PID_FILE)
    except FileNotFoundError:
        pass


def main():
    if "--kill" in sys.argv:
        kill_existing()
        return

    kill_existing()

    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))

    server = ReusableTCPServer(("127.0.0.1", PORT), SoundHandler)
    print(f"Relay listening on 127.0.0.1:{PORT}")
    print(f"PID: {os.getpid()}, Volume: {VOLUME}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
        try:
            os.remove(PID_FILE)
        except FileNotFoundError:
            pass


if __name__ == "__main__":
    main()

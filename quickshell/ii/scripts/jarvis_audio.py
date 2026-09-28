#!/usr/bin/env python3
"""Jarvis Audio Recording & Transcription Script.

Controls audio recording via PipeWire (pw-record) in a toggle fashion and
transcribes recorded speech using the local ROCm Whisper server.

Lifecycle & Resource Management:
- On record start: Starts `whisper-server.service` in background if inactive,
  warming up GPU/VRAM while the user speaks.
- On record stop & transcribe: Transcribes audio, then schedules a 120s idle
  timer to cleanly stop `whisper-server.service`, preserving 0 VRAM at rest.
"""

import sys
import os
import signal
import time
import subprocess
import json
import urllib.request
import argparse

PID_FILE = "/tmp/jarvis_recording.pid"
AUDIO_FILE = "/tmp/jarvis_input.wav"
DEFAULT_SERVER_URL = "http://127.0.0.1:8085/inference"
IDLE_STOP_UNIT = "whisper-idle-stop"
IDLE_TIMEOUT_SECONDS = 120


def cancel_idle_timer():
    """Cancels any pending idle shutdown timer."""
    subprocess.run(
        ["systemctl", "--user", "stop", f"{IDLE_STOP_UNIT}.timer"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def schedule_idle_timer(seconds: int = IDLE_TIMEOUT_SECONDS):
    """Schedules an automatic shutdown of whisper-server after inactivity."""
    cancel_idle_timer()
    subprocess.run(
        [
            "systemd-run",
            "--user",
            f"--unit={IDLE_STOP_UNIT}",
            f"--on-active={seconds}s",
            "systemctl",
            "--user",
            "stop",
            "whisper-server.service",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def ensure_whisper_started():
    """Starts whisper-server.service in background if not already running."""
    cancel_idle_timer()
    res = subprocess.run(
        ["systemctl", "--user", "is-active", "--quiet", "whisper-server.service"]
    )
    if res.returncode != 0:
        subprocess.Popen(
            ["systemctl", "--user", "start", "whisper-server.service"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


def wait_for_whisper_ready(server_url: str = DEFAULT_SERVER_URL, timeout: float = 6.0) -> bool:
    """Waits until whisper-server HTTP endpoint is responding."""
    start_time = time.time()
    base_url = server_url.rsplit("/", 1)[0] if "/inference" in server_url else server_url
    while time.time() - start_time < timeout:
        try:
            req = urllib.request.Request(base_url, method="HEAD")
            with urllib.request.urlopen(req, timeout=0.8) as resp:
                if resp.status == 200:
                    return True
        except Exception:
            time.sleep(0.15)
    return False


def get_recording_pid() -> int | None:
    if not os.path.exists(PID_FILE):
        return None
    try:
        with open(PID_FILE, "r") as f:
            pid = int(f.read().strip())
        os.kill(pid, 0)
        return pid
    except (ValueError, OSError):
        try:
            os.remove(PID_FILE)
        except OSError:
            pass
        return None


def start_recording(audio_path: str = AUDIO_FILE) -> int:
    existing_pid = get_recording_pid()
    if existing_pid:
        return existing_pid

    # Warm up Whisper server in parallel while user speaks
    ensure_whisper_started()

    # Clean previous audio file
    if os.path.exists(audio_path):
        try:
            os.remove(audio_path)
        except OSError:
            pass

    # Launch pw-record in a detached session (16kHz 16-bit mono PCM)
    proc = subprocess.Popen(
        [
            "pw-record",
            "--rate", "16000",
            "--channels", "1",
            "--format", "s16",
            audio_path,
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )

    with open(PID_FILE, "w") as f:
        f.write(str(proc.pid))

    return proc.pid


def stop_recording(audio_path: str = AUDIO_FILE) -> bool:
    pid = get_recording_pid()
    if not pid:
        if os.path.exists(PID_FILE):
            try:
                os.remove(PID_FILE)
            except OSError:
                pass
        return False

    try:
        # SIGINT signals pw-record to finish and write headers cleanly
        os.kill(pid, signal.SIGINT)
    except OSError:
        pass

    deadline = time.time() + 2.0
    while time.time() < deadline:
        try:
            os.kill(pid, 0)
            time.sleep(0.05)
        except OSError:
            break
    else:
        try:
            os.kill(pid, signal.SIGKILL)
        except OSError:
            pass

    if os.path.exists(PID_FILE):
        try:
            os.remove(PID_FILE)
        except OSError:
            pass

    return True


def transcribe(
    audio_path: str = AUDIO_FILE,
    server_url: str = DEFAULT_SERVER_URL,
    language: str = "es",
    auto_stop_idle: bool = True,
) -> str:
    if not os.path.exists(audio_path):
        return ""

    if os.path.getsize(audio_path) < 500:
        return ""

    # Ensure server is ready before posting audio
    wait_for_whisper_ready(server_url)

    cmd = [
        "curl", "-s",
        "-F", f"file=@{audio_path}",
        "-F", "response_format=json",
        "-F", f"language={language}",
        server_url,
    ]

    text = ""
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if result.returncode == 0 and result.stdout:
            data = json.loads(result.stdout)
            text = data.get("text", "").strip()
        else:
            print(f"Whisper server error: {result.stderr}", file=sys.stderr)
    except Exception as e:
        print(f"Error during transcription: {e}", file=sys.stderr)

    # Schedule shutdown after 120s of idle time
    if auto_stop_idle:
        schedule_idle_timer(IDLE_TIMEOUT_SECONDS)

    return text


def main():
    parser = argparse.ArgumentParser(description="Jarvis audio recorder & Whisper transcriber")
    parser.add_argument(
        "action",
        nargs="?",
        default="toggle",
        choices=["toggle", "start", "stop", "status", "transcribe", "server-stop"],
        help="Action to perform (default: toggle)",
    )
    parser.add_argument("-f", "--file", default=AUDIO_FILE, help="Audio file path")
    parser.add_argument("-s", "--server", default=DEFAULT_SERVER_URL, help="Whisper server URL")
    parser.add_argument("-l", "--language", default="es", help="Transcription language (default: es)")
    parser.add_argument("--json", action="store_true", help="Output result as JSON")
    parser.add_argument("--no-idle-stop", action="store_true", help="Do not schedule auto-stop after transcription")
    parser.add_argument("--dispatch", action="store_true", help="Dispatch transcript to Jarvis dispatcher on stop/transcribe")

    args = parser.parse_args()
    auto_stop = not args.no_idle_stop

    def handle_dispatch(transcribed_text: str):
        if not args.dispatch or not transcribed_text:
            return None
        try:
            from jarvis_dispatcher import dispatch_transcript
            return dispatch_transcript(transcribed_text)
        except Exception as e:
            print(f"Error during dispatch: {e}", file=sys.stderr)
            return None

    if args.action == "server-stop":
        cancel_idle_timer()
        subprocess.run(["systemctl", "--user", "stop", "whisper-server.service"])
        if args.json:
            print(json.dumps({"status": "stopped"}))
        else:
            print("whisper-server stopped")
        sys.exit(0)

    elif args.action == "status":
        pid = get_recording_pid()
        whisper_active = (
            subprocess.run(
                ["systemctl", "--user", "is-active", "--quiet", "whisper-server.service"]
            ).returncode
            == 0
        )
        if args.json:
            print(
                json.dumps(
                    {
                        "recording": pid is not None,
                        "pid": pid,
                        "whisper_active": whisper_active,
                    }
                )
            )
        else:
            print("recording" if pid else "idle")
        sys.exit(0)

    elif args.action == "start":
        pid = start_recording(args.file)
        if args.json:
            print(json.dumps({"status": "recording", "pid": pid}))
        else:
            print(f"RECORDING:{pid}")
        sys.exit(0)

    elif args.action == "stop":
        stopped = stop_recording(args.file)
        text = transcribe(args.file, args.server, args.language, auto_stop) if stopped else ""
        dispatch_res = handle_dispatch(text)
        if args.json:
            out = {"status": "transcribed", "text": text}
            if dispatch_res is not None:
                out["dispatch"] = dispatch_res
            print(json.dumps(out))
        else:
            print(text)
        sys.exit(0)

    elif args.action == "transcribe":
        text = transcribe(args.file, args.server, args.language, auto_stop)
        dispatch_res = handle_dispatch(text)
        if args.json:
            out = {"status": "transcribed", "text": text}
            if dispatch_res is not None:
                out["dispatch"] = dispatch_res
            print(json.dumps(out))
        else:
            print(text)
        sys.exit(0)

    elif args.action == "toggle":
        pid = get_recording_pid()
        if pid:
            # Currently recording -> stop and transcribe
            stop_recording(args.file)
            text = transcribe(args.file, args.server, args.language, auto_stop)
            dispatch_res = handle_dispatch(text)
            if args.json:
                out = {"status": "transcribed", "text": text}
                if dispatch_res is not None:
                    out["dispatch"] = dispatch_res
                print(json.dumps(out))
            else:
                print(text)
        else:
            # Not recording -> start recording
            new_pid = start_recording(args.file)
            if args.json:
                print(json.dumps({"status": "recording", "pid": new_pid}))
            else:
                print(f"RECORDING:{new_pid}")
        sys.exit(0)


if __name__ == "__main__":
    main()

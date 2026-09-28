#!/usr/bin/env python3
"""Jarvis Piper TTS runner.

Synthesizes speech using local Piper TTS and plays it directly via PipeWire (pw-play) or PulseAudio (paplay).
Accepts input text as command line arguments or via stdin.
"""

import sys
import os
import shutil
import subprocess
import argparse

DEFAULT_VOICE = os.path.expanduser("~/.local/share/piper-voices/es_ES-davefx-medium.onnx")
PIPER_BIN = "/usr/bin/piper-tts"


def speak(text: str, voice: str = DEFAULT_VOICE, output_wav: str = None, speed: float = 1.0) -> bool:
    if not text or not text.strip():
        return False

    piper_exe = PIPER_BIN if os.path.isfile(PIPER_BIN) and os.access(PIPER_BIN, os.X_OK) else shutil.which("piper-tts")
    if not piper_exe:
        print("Error: piper-tts binary not found", file=sys.stderr)
        return False

    voice_path = os.path.expanduser(voice)
    if not os.path.isfile(voice_path):
        print(f"Error: Voice model not found at {voice_path}", file=sys.stderr)
        return False

    piper_cmd = [
        piper_exe,
        "--model", voice_path,
        "-q",
    ]

    if speed != 1.0 and speed > 0:
        # length_scale is phoneme length multiplier (smaller = faster)
        piper_cmd.extend(["--length_scale", str(1.0 / speed)])

    if output_wav:
        output_path = os.path.expanduser(output_wav)
        piper_cmd.extend(["--output_file", output_path])
        try:
            proc = subprocess.Popen(piper_cmd, stdin=subprocess.PIPE)
            proc.communicate(input=text.encode("utf-8"))
            return proc.returncode == 0
        except Exception as e:
            print(f"Error executing piper-tts: {e}", file=sys.stderr)
            return False

    # Direct playback via pw-play or paplay
    piper_cmd.extend(["--output_file", "-"])
    player_bin = shutil.which("pw-play") or shutil.which("paplay")
    if not player_bin:
        print("Error: neither pw-play nor paplay found for playback", file=sys.stderr)
        return False

    try:
        piper_proc = subprocess.Popen(
            piper_cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        player_proc = subprocess.Popen(
            [player_bin, "-"],
            stdin=piper_proc.stdout,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE
        )
        # Allow piper_proc to receive SIGPIPE if player_proc terminates early
        piper_proc.stdout.close()

        piper_proc.communicate(input=text.encode("utf-8"))
        player_proc.wait()
        return player_proc.returncode == 0
    except Exception as e:
        print(f"Error during TTS playback: {e}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(description="Jarvis Piper TTS runner")
    parser.add_argument("text", nargs="*", help="Text to speak. If empty, reads from stdin.")
    parser.add_argument("-v", "--voice", default=DEFAULT_VOICE, help="Path to piper ONNX model")
    parser.add_argument("-o", "--output", default=None, help="Save to WAV file instead of playing")
    parser.add_argument("-s", "--speed", type=float, default=1.0, help="Speech speed multiplier (default: 1.0)")

    args = parser.parse_args()

    if args.text:
        text = " ".join(args.text).strip()
    else:
        text = sys.stdin.read().strip()

    if not text:
        sys.exit(0)

    success = speak(text, voice=args.voice, output_wav=args.output, speed=args.speed)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

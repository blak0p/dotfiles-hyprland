#!/usr/bin/env python3
"""Jarvis Dictation Mode & State Handler.

Manages desktop dictation mode state, evaluates speech transcripts against
trigger phrases to transition between control mode and dictation mode, and
injects transcribed text directly into the focused Wayland window via wtype.

State Persistence:
- Path: /tmp/jarvis_state.json
- Schema: {"dictation_mode": bool, "last_updated": float}

Triggers:
- Enter Dictation Mode: "modo transcripción", "modo dictado", "activar dictado/transcripción"
- Exit Dictation Mode: "jarvis", "con jarvis", "modo control", "salir de transcripción"
"""

import sys
import os
import time
import json
import re
import shutil
import unicodedata
import subprocess
import argparse

STATE_FILE = "/tmp/jarvis_state.json"
WTYPE_BIN = "/usr/bin/wtype"

ENTER_TRIGGERS = [
    "modo transcripcion",
    "modo dictado",
    "activar transcripcion",
    "activar dictado",
    "activar el modo transcripcion",
    "activar el modo dictado",
    "activa la transcripcion",
    "activa el dictado",
    "activa el modo transcripcion",
    "activa el modo dictado",
    "iniciar transcripcion",
    "iniciar dictado",
    "empezar transcripcion",
    "empezar dictado",
    "poner modo transcripcion",
    "poner modo dictado",
]

EXIT_TRIGGERS = [
    "con jarvis",
    "hola jarvis",
    "hey jarvis",
    "oye jarvis",
    "ok jarvis",
    "jarvis",
    "modo control",
    "activar modo control",
    "activa modo control",
    "activa el modo control",
    "salir de transcripcion",
    "salir de dictado",
    "salir del modo transcripcion",
    "salir del modo dictado",
    "cancelar transcripcion",
    "cancelar dictado",
    "desactivar transcripcion",
    "desactivar dictado",
    "terminar transcripcion",
    "terminar dictado",
]


def normalize_text(text: str) -> str:
    """Normalizes text for robust phrase matching.

    Converts to lowercase, strips accents/diacritics, removes leading and
    trailing punctuation, and collapses multiple whitespace characters.
    """
    if not text:
        return ""
    text = text.strip().lower()
    # Normalize unicode to decompose accents (e.g. 'ó' -> 'o' + combining accent)
    nfkd = unicodedata.normalize("NFKD", text)
    without_accents = "".join(c for c in nfkd if not unicodedata.combining(c))
    # Strip leading and trailing punctuation (preserve internal spaces and alphanumeric)
    cleaned = re.sub(r"^[^\w\s]+|[^\w\s]+$", "", without_accents)
    # Collapse multiple whitespaces
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    return cleaned


def get_state() -> dict:
    """Reads current Jarvis dictation state from /tmp/jarvis_state.json."""
    if not os.path.exists(STATE_FILE):
        return {"dictation_mode": False, "last_updated": 0.0}
    try:
        with open(STATE_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            if isinstance(data, dict):
                return {
                    "dictation_mode": bool(data.get("dictation_mode", False)),
                    "last_updated": float(data.get("last_updated", 0.0)),
                }
    except Exception:
        pass
    return {"dictation_mode": False, "last_updated": 0.0}


def set_dictation_mode(active: bool) -> None:
    """Atomically persists dictation state to /tmp/jarvis_state.json."""
    state = {
        "dictation_mode": bool(active),
        "last_updated": time.time(),
    }
    tmp_path = f"{STATE_FILE}.tmp.{os.getpid()}"
    try:
        with open(tmp_path, "w", encoding="utf-8") as f:
            json.dump(state, f, indent=2)
        os.replace(tmp_path, STATE_FILE)
    except Exception:
        # Fallback to direct write
        try:
            with open(STATE_FILE, "w", encoding="utf-8") as f:
                json.dump(state, f, indent=2)
        except Exception:
            pass


def type_to_focused_window(text: str) -> bool:
    """Types text directly into the currently focused Wayland window via wtype.

    Appends a trailing space for natural continuous dictation flow.
    Uses argument list passing to avoid shell escaping issues.
    """
    if not text:
        return False

    wtype_exe = WTYPE_BIN if os.path.isfile(WTYPE_BIN) and os.access(WTYPE_BIN, os.X_OK) else shutil.which("wtype")
    if not wtype_exe:
        print("Error: wtype binary not found in system", file=sys.stderr)
        return False

    text_with_space = text.rstrip() + " "
    try:
        proc = subprocess.run(
            [wtype_exe, "--", text_with_space],
            capture_output=True,
            text=True,
            timeout=5,
        )
        return proc.returncode == 0
    except Exception as e:
        print(f"Error executing wtype: {e}", file=sys.stderr)
        return False


def evaluate_transcript(text: str) -> dict:
    """Evaluates transcribed text and decides action based on current state.

    State transitions:
    - In normal mode (dictation_mode == False):
      - If user asks to activate dictation -> activates dictation, returns {"action": "enter_dictation"}
      - Otherwise -> returns {"action": "forward_assistant", "text": text}
    - In dictation mode (dictation_mode == True):
      - If user asks to exit dictation -> deactivates dictation, returns {"action": "exit_dictation"}
        (If extra command follows trigger e.g. "con jarvis qué hora es", returns forward_text)
      - Otherwise -> returns {"action": "type_text", "text": text}
    """
    if not text or not text.strip():
        return {"action": "none"}

    state = get_state()
    in_dictation = state.get("dictation_mode", False)
    cleaned = normalize_text(text)

    # Sort triggers by length descending to prioritize longer phrases
    sorted_enter = sorted(ENTER_TRIGGERS, key=len, reverse=True)
    sorted_exit = sorted(EXIT_TRIGGERS, key=len, reverse=True)

    if not in_dictation:
        # Check if text matches any enter trigger
        matched_trigger = None
        for trigger in sorted_enter:
            if cleaned == trigger or cleaned.startswith(trigger + " ") or cleaned.endswith(" " + trigger):
                matched_trigger = trigger
                break

        if matched_trigger:
            set_dictation_mode(True)
            return {
                "action": "enter_dictation",
                "trigger": matched_trigger,
                "text": text,
            }
        else:
            return {
                "action": "forward_assistant",
                "text": text,
            }
    else:
        # Currently in dictation mode: check if text matches exit triggers
        matched_exit = None
        remainder = ""

        for trigger in sorted_exit:
            if cleaned == trigger:
                matched_exit = trigger
                break
            elif cleaned.startswith(trigger + " "):
                matched_exit = trigger
                remainder_clean = cleaned[len(trigger):].strip()
                if remainder_clean:
                    remainder = remainder_clean
                break
            elif cleaned.endswith(" " + trigger):
                matched_exit = trigger
                break

        if matched_exit:
            set_dictation_mode(False)
            res = {
                "action": "exit_dictation",
                "trigger": matched_exit,
                "text": text,
            }
            if remainder:
                res["forward_text"] = remainder
            return res
        else:
            return {
                "action": "type_text",
                "text": text,
            }


def main():
    parser = argparse.ArgumentParser(description="Jarvis Dictation State & Handler")
    subparsers = parser.add_subparsers(dest="subcommand", help="Subcommand to execute")

    # get-state
    subparsers.add_parser("get-state", help="Print current dictation state as JSON")

    # set-state
    set_parser = subparsers.add_parser("set-state", help="Set dictation mode active/inactive")
    set_parser.add_argument("state", choices=["on", "off", "true", "false", "1", "0"], help="Target state")

    # toggle
    subparsers.add_parser("toggle", help="Toggle dictation mode state")

    # evaluate
    eval_parser = subparsers.add_parser("evaluate", help="Evaluate transcript text")
    eval_parser.add_argument("text", help="Transcribed text to evaluate")

    # type
    type_parser = subparsers.add_parser("type", help="Inject text via wtype")
    type_parser.add_argument("text", help="Text to inject into focused window")

    # is-active
    subparsers.add_parser("is-active", help="Exit code 0 if dictation mode is active, 1 otherwise")

    args = parser.parse_args()

    if args.subcommand == "get-state":
        state = get_state()
        print(json.dumps(state, indent=2))
        sys.exit(0)

    elif args.subcommand == "set-state":
        active = args.state in ("on", "true", "1")
        set_dictation_mode(active)
        state = get_state()
        print(json.dumps(state, indent=2))
        sys.exit(0)

    elif args.subcommand == "toggle":
        state = get_state()
        new_active = not state.get("dictation_mode", False)
        set_dictation_mode(new_active)
        print(json.dumps(get_state(), indent=2))
        sys.exit(0)

    elif args.subcommand == "is-active":
        state = get_state()
        sys.exit(0 if state.get("dictation_mode", False) else 1)

    elif args.subcommand == "evaluate":
        res = evaluate_transcript(args.text)
        print(json.dumps(res, indent=2))
        sys.exit(0)

    elif args.subcommand == "type":
        ok = type_to_focused_window(args.text)
        print(json.dumps({"success": ok, "text": args.text}))
        sys.exit(0 if ok else 1)

    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()

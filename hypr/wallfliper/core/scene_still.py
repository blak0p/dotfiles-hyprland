"""Static still of a Wallpaper Engine scene for lock-screen/fallback syncing.

linux-wallpaperengine has no headless renderer: it presents through a
wlr-layer-shell surface. To get a still we launch a short-lived instance with
`--screenshot`, poll for the output file, and kill it the moment it appears.
Because the live engine is already painting the same scene, the brief second
instance renders identical pixels and is invisible. Best-effort: any failure
returns None and the caller skips the shell-state sync (the scene itself
still works).
"""

from __future__ import annotations

import json
import shutil
import subprocess
import time
from pathlib import Path

from .state import cache_dir

_SCREENSHOT_DELAY_FRAMES = 20  # at --fps 30 ≈ 0.7s of rendering before capture
_POLL_TIMEOUT_S = 20.0
_POLL_INTERVAL_S = 0.2
_TERMINATE_TIMEOUT_S = 2.0

# Mirrors the live engine's flags in set_scene so the captured frame matches
# what is on screen (scaling fill, particles off, muted).
_ENGINE_FLAGS = (
    "--disable-mouse",
    "--disable-parallax",
    "--disable-particles",
    "--scaling",
    "fill",
    "--silent",
)


def scene_still(scene_dir: Path) -> Path | None:
    """Render a PNG still of `scene_dir` (the resolved `.scene` target).

    Cached under ~/.cache/wallfliper/scene-stills/ keyed by the scene
    directory name (a workshop id for Steam scenes, so it stays stable across
    re-applies). Returns None — and cleans up any partial file — when the
    engine is missing, times out, or fails; the caller degrades to no sync.
    """
    engine = shutil.which("linux-wallpaperengine")
    if engine is None:
        return None
    out = cache_dir() / "scene-stills" / f"{scene_dir.name}.png"
    if out.exists() and out.stat().st_size > 0:
        return out
    try:
        out.parent.mkdir(parents=True, exist_ok=True)
    except OSError:
        return None
    proc = subprocess.Popen(
        [
            engine,
            "--screenshot", str(out),
            "--screenshot-delay", str(_SCREENSHOT_DELAY_FRAMES),
            "--screen-root", _focused_monitor(),
            "--bg", str(scene_dir),
            *list(_ENGINE_FLAGS),
            "--fps", "30",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        stdin=subprocess.DEVNULL,
        start_new_session=True,
    )
    try:
        deadline = time.monotonic() + _POLL_TIMEOUT_S
        while time.monotonic() < deadline:
            if out.exists() and out.stat().st_size > 0:
                return out
            if proc.poll() is not None:
                break
            time.sleep(_POLL_INTERVAL_S)
    finally:
        _terminate(proc)
    out.unlink(missing_ok=True)
    return None


def _focused_monitor() -> str:
    """Name of the currently focused monitor via hyprctl, or '*' on any failure.

    A single monitor is enough for a still; '*' would be ambiguous when the
    scene spans multiple outputs.
    """
    try:
        result = subprocess.run(
            ["hyprctl", "monitors", "-j"],
            capture_output=True, text=True, check=False, timeout=5.0,
        )
        monitors = json.loads(result.stdout)
        if monitors:
            focused = next((m for m in monitors if m.get("focused")), monitors[0])
            return focused.get("name", "*")
    except Exception:
        pass
    return "*"


def _terminate(proc: subprocess.Popen) -> None:
    """Stop the still instance gracefully (SIGTERM), escalate to SIGKILL."""
    try:
        proc.terminate()
    except OSError:
        pass
    try:
        proc.wait(timeout=_TERMINATE_TIMEOUT_S)
    except subprocess.TimeoutExpired:
        try:
            proc.kill()
        except OSError:
            pass

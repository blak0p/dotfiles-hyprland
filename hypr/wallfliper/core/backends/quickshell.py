"""Wallpaper backend that delegates to the illogical-impulse Quickshell stack.

This backend does NOT paint the wallpaper itself — the Quickshell `Background`
module (host/config/quickshell/ii/modules/ii/background/Background.qml) reads
`Config.options.background.wallpaperPath` from
`~/.config/illogical-impulse/config.json` and draws the image as a wlr-layer
Background layer. Our job is only to:

  1. Update that config path (the `switchwall.sh --image <path>` call does it
     AND runs matugen + generates material_colors.scss + applies the colors).
  2. For video, spawn `mpvpaper` directly (same as switchwall.sh does).

Why not use the wlroots swww backend: Quickshell is already painting the
wallpaper, so running swww too would double-paint. Why not patch switchwall
out: switchwall.sh is the single source of truth for colors + path + video
restore in this dotfiles, so we reuse it instead of duplicating its logic.

`--image <path>` is the documented switchwall.sh flag for "set this image".
We pass the dark/light mode through `--mode dark|light` when the user toggled
it in wallfliper (not tracked here yet — defaults to switchwall's auto-detect).
"""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
from pathlib import Path

from ..scene_still import scene_still
from .base import BackendError, ImageTransition, MissingDependencyError, WallpaperBackend
from .wlroots import WlrootsBackend


# Path to the illogical-impulse switchwall.sh. Resolved from the dotfiles
# layout (host/config/quickshell/ii/scripts/colors/switchwall.sh). We look it
# up relative to the user's config dir to stay correct across reinstalls.
_SWITCHWALL_CANDIDATES = (
    os.path.expanduser(
        "~/.config/quickshell/ii/scripts/colors/switchwall.sh"
    ),
    os.path.expanduser(
        "~/.config/hypr/hyprland/scripts/colors/switchwall.sh"
    ),
)

# The two places the shell reads its wallpaper from. Scenes never go through
# switchwall.sh, so both stay stale unless set_scene syncs them to the still.
_SHELL_CONFIG = os.path.expanduser("~/.config/illogical-impulse/config.json")
_HYPRLOCK_COLORS = os.path.expanduser("~/.config/hypr/hyprlock/colors.conf")
_BACKGROUND_LINE = re.compile(r"^\$background_image\s*=.*$", re.MULTILINE)


def _resolve_switchwall() -> str:
    for candidate in _SWITCHWALL_CANDIDATES:
        if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
            return candidate
    raise BackendError(
        "switchwall.sh not found in any of: "
        + ", ".join(_SWITCHWALL_CANDIDATES)
    )


class QuickshellBackend(WallpaperBackend):
    """Delegates wallpaper apply to illogical-impulse's switchwall.sh.

    - set_image: `switchwall.sh --image <path>` (updates config + matugen +
      material colors + applies via Quickshell Background).
    - set_video: `mpvpaper` directly (switchwall.sh does the same for video),
      plus `switchwall.sh --image <first-frame>` first so colors still match.
    - set_scene: delegates to the wlroots backend (linux-wallpaperengine) since
      switchwall.sh has no concept of scene wallpapers.
    """

    def __init__(self) -> None:
        self._wlroots: WlrootsBackend | None = None

    def is_available(self) -> bool:
        try:
            _resolve_switchwall()
            return True
        except BackendError:
            return False

    def set_image(
        self, path: Path, transition: ImageTransition | None = None
    ) -> None:
        # transition is ignored: Quickshell's Background.qml crossfades on its
        # own when wallpaperPath changes, so there's nothing for us to animate.
        WlrootsBackend._stop_scene()  # kill linux-wallpaperengine if running
        script = _resolve_switchwall()
        try:
            subprocess.run(
                [script, "--image", str(path)],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=True,
            )
        except subprocess.CalledProcessError as exc:
            raise BackendError(
                f"switchwall.sh failed (exit {exc.returncode}): "
                f"{exc.stderr.strip()}"
            ) from exc

    def set_scene(self, path: Path) -> None:
        """Apply a Wallpaper Engine scene via linux-wallpaperengine.

        Delegates to the wlroots backend since switchwall.sh has no scene
        support. Lazy-init the backend so a missing binary only errors when
        a scene is actually applied (not on every `is_available` check).
        """
        if self._wlroots is None:
            self._wlroots = WlrootsBackend()
            try:
                self._wlroots._require("linux-wallpaperengine")
            except MissingDependencyError:
                raise BackendError(
                    "linux-wallpaperengine is required for scene wallpapers."
                ) from None
        self._wlroots.set_scene(path)
        # Scenes never reach switchwall.sh, so the shell's wallpaper sources
        # would keep showing whatever image was last set. Point them at a
        # rendered still so the lock screen and the fallback layer under the
        # live scene match the scene. Best-effort: a failed render skips sync.
        still = scene_still(path.resolve())
        if still is not None:
            _sync_shell_background(still)

    def set_video(
        self, path: Path, transition: ImageTransition | None = None
    ) -> None:
        # For video, mirror what switchwall.sh does itself: spawn mpvpaper for
        # every monitor. switchwall.sh also extracts a first frame for color
        # generation and writes a __restore_video_wallpaper.sh for login — so
        # the simplest correct path is to just call switchwall.sh with the
        # video path (its `is_video` branch handles everything). The `--image`
        # flag works for videos too because switchwall.sh detects the extension.
        WlrootsBackend._stop_scene()  # kill linux-wallpaperengine if running
        script = _resolve_switchwall()
        try:
            subprocess.run(
                [script, "--image", str(path)],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=True,
            )
        except subprocess.CalledProcessError as exc:
            raise BackendError(
                f"switchwall.sh failed (exit {exc.returncode}): "
                f"{exc.stderr.strip()}"
            ) from exc


def _sync_shell_background(still: Path) -> None:
    """Point the shell's wallpaper sources at a still of the applied scene.

    Writes the still into the illogical-impulse config (what paints the
    quickshell background layer and what the lock screen reads) and into the
    hyprlock `$background_image` variable (matugen's lock-screen source). Both
    are atomically replaced like switchwall.sh does, and the next image/video
    apply overwrites them again through the normal pipeline. Idempotent: if the
    still is already in place, nothing is written — quickshell watches
    config.json (Config.qml `watchChanges`) and reloads on ANY change, which
    repaints the still layer over the live engine at login. Best-effort and
    never raises: a failed sync must not break the already-applied scene.
    """
    path = str(still)
    try:
        cfg = json.loads(Path(_SHELL_CONFIG).read_text())
    except (OSError, json.JSONDecodeError):
        cfg = {}
    if cfg.get("background", {}).get("wallpaperPath") == path:
        return
    cfg.setdefault("background", {})
    cfg["background"]["wallpaperPath"] = path
    cfg["background"]["thumbnailPath"] = path
    try:
        _atomic_write(Path(_SHELL_CONFIG), json.dumps(cfg, indent=2) + "\n")
    except OSError:
        return
    _set_hyprlock_background(path)


def _set_hyprlock_background(path: str) -> None:
    """Replace the `$background_image` line in hyprlock's colors.conf."""
    colors = Path(_HYPRLOCK_COLORS)
    try:
        text = colors.read_text()
    except OSError:
        return
    line = f"$background_image = {path}"
    if _BACKGROUND_LINE.search(text):
        text = _BACKGROUND_LINE.sub(line, text)
    else:
        text = text.rstrip() + "\n" + line + "\n"
    try:
        _atomic_write(colors, text)
    except OSError:
        pass


def _atomic_write(path: Path, content: str) -> None:
    """Write `content` to `path` via a same-dir tmp + rename (atomic)."""
    tmp = Path(str(path) + ".tmp")
    tmp.write_text(content)
    tmp.replace(path)
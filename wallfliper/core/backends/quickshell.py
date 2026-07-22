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

import os
import shutil
import subprocess
from pathlib import Path

from .base import BackendError, ImageTransition, WallpaperBackend


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
    """

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

    def set_video(
        self, path: Path, transition: ImageTransition | None = None
    ) -> None:
        # For video, mirror what switchwall.sh does itself: spawn mpvpaper for
        # every monitor. switchwall.sh also extracts a first frame for color
        # generation and writes a __restore_video_wallpaper.sh for login — so
        # the simplest correct path is to just call switchwall.sh with the
        # video path (its `is_video` branch handles everything). The `--image`
        # flag works for videos too because switchwall.sh detects the extension.
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
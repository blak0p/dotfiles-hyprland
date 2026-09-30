#!/usr/bin/env python3
import os
import sys
import json
import urllib.request
import urllib.parse
import urllib.error
import argparse
import re
import configparser
import difflib
import shlex
import shutil
import subprocess
import time
import unicodedata

SESSION_FILE = "/tmp/quickshell_island_ai_session.json"
ENDPOINT = "http://127.0.0.1:8090/v1/chat/completions"
MODEL = "gemma-4"
LLAMA_IDLE_STOP_UNIT = "llama-idle-stop"
LLAMA_IDLE_TIMEOUT_SECONDS = 60


def cancel_llama_idle_timer():
    """Cancels any pending llama-server idle stop timer."""
    subprocess.run(
        ["systemctl", "--user", "stop", f"{LLAMA_IDLE_STOP_UNIT}.timer"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def schedule_llama_idle_timer(seconds: int = LLAMA_IDLE_TIMEOUT_SECONDS):
    """Schedules automatic stop of llama-server.service after inactivity."""
    cancel_llama_idle_timer()
    subprocess.run(
        [
            "systemd-run",
            "--user",
            f"--unit={LLAMA_IDLE_STOP_UNIT}",
            f"--on-active={seconds}s",
            "systemctl",
            "--user",
            "stop",
            "llama-server.service",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def ensure_llama_server_running(timeout: float = 5.0) -> bool:
    """Ensures llama-server.service is running and ready to accept HTTP requests."""
    cancel_llama_idle_timer()
    res = subprocess.run(
        ["systemctl", "--user", "is-active", "--quiet", "llama-server.service"]
    )
    if res.returncode != 0:
        subprocess.run(
            ["systemctl", "--user", "start", "llama-server.service"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        start_t = time.time()
        while time.time() - start_t < timeout:
            try:
                req = urllib.request.Request("http://127.0.0.1:8090/v1/models")
                with urllib.request.urlopen(req, timeout=0.5) as r:
                    if r.status == 200:
                        return True
            except Exception:
                time.sleep(0.1)
        return False
    return True


SYSTEM_PROMPT = """You are a lightning-fast, concise desktop assistant embedded in a Hyprland Linux Dynamic Island.
You have access to tools for live web search, local filesystem inspection, listing installed applications and games (list_desktop_apps), launching applications (launch_app), controlling Spotify playback, and checking AI model usage quotas.
IMPORTANT: Detect the user's language and ALWAYS answer in the exact same language (e.g., Spanish if asked in Spanish).
When launching an app or game, if the user's request is ambiguous (e.g. asking for 'Zelda' or 'Mario' when multiple options exist), do NOT guess or launch one arbitrarily: use list_desktop_apps or launch_app to find matching options, and ask the user which specific one they want to open.
Keep your answers direct, crisp, and formatted in clean markdown without fluff or pleasantries, as the display area is a compact floating card.
Do not repeat or quote raw tool outputs; summarize the answer cleanly."""

TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "web_search",
            "description": "Searches the web and returns relevant snippets.",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "The search query."}
                },
                "required": ["query"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "read_file",
            "description": "Reads a local file up to a maximum number of lines.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Path to the file."}
                },
                "required": ["path"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "list_dir",
            "description": "Lists the contents of a directory.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Path to the directory."}
                },
                "required": ["path"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "list_desktop_apps",
            "description": "Lists installed desktop applications, games, and .desktop entries. Can optionally filter by keyword, category, or title (e.g. 'mario', 'zelda', 'game', 'emulator'). Use this to see what apps/games exist or to resolve ambiguity.",
            "parameters": {
                "type": "object",
                "properties": {
                    "filter": {
                        "type": "string",
                        "description": "Optional keyword or category to filter by (e.g. 'mario', 'zelda', 'game', or null for all)."
                    }
                }
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "launch_app",
            "description": "Launches an installed desktop application by name or alias.",
            "parameters": {
                "type": "object",
                "properties": {
                    "app_name": {
                        "type": "string",
                        "description": "Name or keyword of the application to launch (e.g. 'firefox', 'spotify', 'obs', 'discord', 'steam')."
                    }
                },
                "required": ["app_name"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "spotify_control",
            "description": "Controls Spotify playback or searches/plays music via MPRIS / D-Bus.",
            "parameters": {
                "type": "object",
                "properties": {
                    "action": {
                        "type": "string",
                        "enum": ["play", "pause", "play_pause", "next", "previous", "status", "search_play"],
                        "description": "Action to perform on Spotify."
                    },
                    "query": {
                        "type": "string",
                        "description": "Search query for track, album, or artist if action is search_play."
                    }
                },
                "required": ["action"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "check_ai_quotas",
            "description": "Checks remaining AI model usage quotas, rate limits, and reset times across connected providers (Codex, Antigravity, Claude, Gemini, OpenAI, etc.) using codexbar.",
            "parameters": {
                "type": "object",
                "properties": {
                    "provider": {
                        "type": "string",
                        "description": "Optional provider name to filter by, e.g. 'codex', 'antigravity', 'claude', or null for all connected providers."
                    }
                }
            }
        }
    }
]

def emit(data):
    print(json.dumps(data), flush=True)

def normalize_text(text: str) -> str:
    """Normalizes text by removing diacritics/accents, stripping, and lowercasing."""
    if not text:
        return ""
    normalized = unicodedata.normalize("NFKD", text)
    stripped = "".join(c for c in normalized if not unicodedata.combining(c))
    return stripped.strip().lower()

DESKTOP_DIRS = [
    "/usr/share/applications",
    os.path.expanduser("~/.local/share/applications"),
    os.path.expanduser("~/Escritorio"),
    "/var/lib/flatpak/exports/share/applications",
    os.path.expanduser("~/.local/share/flatpak/exports/share/applications"),
    "/usr/local/share/applications",
]

def parse_desktop_file(path: str) -> dict:
    """Parses a .desktop file, returning a dictionary if valid application entry."""
    parser = configparser.ConfigParser(interpolation=None)
    section = None
    try:
        parser.read(path, encoding="utf-8")
        if "Desktop Entry" in parser:
            section = parser["Desktop Entry"]
    except Exception:
        pass

    if section is None:
        try:
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                lines = f.readlines()
            data = {}
            in_entry = False
            for line in lines:
                s = line.strip()
                if s == "[Desktop Entry]":
                    in_entry = True
                    continue
                elif s.startswith("[") and s.endswith("]"):
                    in_entry = False
                    continue
                if in_entry and "=" in s:
                    k, v = s.split("=", 1)
                    data[k.strip()] = v.strip()
            if data.get("Type") != "Application":
                return None
            if data.get("NoDisplay", "false").lower() == "true":
                return None
            if data.get("Hidden", "false").lower() == "true":
                return None
            name = data.get("Name", "").strip()
            exec_cmd = data.get("Exec", "").strip()
            if not name or not exec_cmd:
                return None

            generic_names = [v for k, v in data.items() if k.lower().startswith("genericname")]
            keywords_list = [v for k, v in data.items() if k.lower().startswith("keywords") or k.lower().startswith("comment")]
            return {
                "file": os.path.basename(path),
                "path": path,
                "name": name,
                "exec": exec_cmd,
                "generic_name": " ".join(generic_names) if generic_names else data.get("GenericName", "").strip(),
                "keywords": " ".join(keywords_list) if keywords_list else data.get("Keywords", "").strip(),
                "terminal": data.get("Terminal", "false").lower() == "true",
            }
        except Exception:
            return None

    if section.get("Type") != "Application":
        return None
    if section.getboolean("NoDisplay", fallback=False):
        return None
    if section.getboolean("Hidden", fallback=False):
        return None

    name = section.get("Name", "").strip()
    exec_cmd = section.get("Exec", "").strip()
    if not name or not exec_cmd:
        return None

    generic_names = [v for k, v in section.items() if k.startswith("genericname")]
    keywords_list = [v for k, v in section.items() if k.startswith("keywords") or k.startswith("comment")]

    return {
        "file": os.path.basename(path),
        "path": path,
        "name": name,
        "exec": exec_cmd,
        "generic_name": " ".join(generic_names) if generic_names else section.get("GenericName", "").strip(),
        "keywords": " ".join(keywords_list) if keywords_list else section.get("Keywords", "").strip(),
        "terminal": section.getboolean("Terminal", fallback=False),
    }

def scan_desktop_applications():
    """Scans all standard desktop directories and returns list of application records."""
    apps = {}
    for d in DESKTOP_DIRS:
        if not os.path.isdir(d):
            continue
        try:
            entries = os.listdir(d)
        except OSError:
            continue
        for entry in entries:
            if not entry.endswith(".desktop") or entry in apps:
                continue
            full_path = os.path.join(d, entry)
            parsed = parse_desktop_file(full_path)
            if parsed:
                apps[entry] = parsed
    return list(apps.values())

def perform_list_desktop_apps(filter_query: str = None) -> str:
    emit({"type": "tool_start", "name": "list_desktop_apps", "args": {"filter": filter_query}})
    apps = scan_desktop_applications()
    if not apps:
        res = "No desktop applications found."
        emit({"type": "tool_done", "name": "list_desktop_apps", "preview": res})
        return res

    norm_filter = normalize_text(filter_query) if filter_query else ""
    matches = []
    for app in apps:
        if norm_filter:
            haystack = f"{normalize_text(app['name'])} {normalize_text(app.get('generic_name', ''))} {normalize_text(app.get('comment', ''))} {normalize_text(app.get('keywords', ''))} {normalize_text(app.get('categories', ''))} {normalize_text(app['file'])}"
            if norm_filter not in haystack:
                continue
        matches.append(app)

    if not matches:
        res = f"No desktop applications found matching '{filter_query}'."
        emit({"type": "tool_done", "name": "list_desktop_apps", "preview": res})
        return res

    # Deduplicate and sort by name
    unique_matches = {}
    for a in sorted(matches, key=lambda x: x["name"].lower()):
        if a["name"].lower() not in unique_matches:
            unique_matches[a["name"].lower()] = a

    lines = []
    for a in list(unique_matches.values())[:30]:
        desc = a.get("comment") or a.get("generic_name") or ""
        if desc:
            lines.append(f"- **{a['name']}** (`{a['file']}`): {desc}")
        else:
            lines.append(f"- **{a['name']}** (`{a['file']}`)")

    if len(unique_matches) > 30:
        lines.append(f"... and {len(unique_matches) - 30} more applications.")

    res = "\n".join(lines)
    emit({"type": "tool_done", "name": "list_desktop_apps", "preview": f"Found {len(unique_matches)} apps"})
    return res

def perform_launch_app(app_name: str) -> str:
    emit({"type": "tool_start", "name": "launch_app", "args": {"app_name": app_name}})
    if not app_name or not app_name.strip():
        res = "Error: app_name is required."
        emit({"type": "tool_done", "name": "launch_app", "preview": res})
        return res

    norm_target = normalize_text(app_name)
    apps = scan_desktop_applications()
    if not apps:
        res = f"No desktop applications found to match '{app_name}'."
        emit({"type": "tool_done", "name": "launch_app", "preview": res})
        return res

    # 1. Exact match check (full name or desktop filename without extension)
    exact_matches = [
        app for app in apps
        if norm_target in (normalize_text(app["name"]), normalize_text(os.path.splitext(app["file"])[0]))
    ]
    if len(exact_matches) == 1:
        best_app = exact_matches[0]
    else:
        candidates = []
        for app in apps:
            score = 0.0
            norm_name = normalize_text(app["name"])
            norm_file = normalize_text(os.path.splitext(app["file"])[0])
            norm_exec_bin = normalize_text(app["exec"].split()[0] if app["exec"] else "")
            norm_generic = normalize_text(app.get("generic_name", ""))
            norm_keywords = normalize_text(app.get("keywords", ""))

            target_words = norm_target.split()
            all_words_in_name = all(w in norm_name for w in target_words)

            if norm_target in (norm_name, norm_file, norm_exec_bin):
                score = 100.0
            elif all_words_in_name:
                score = 85.0
            elif norm_target in norm_generic:
                score = 80.0
            elif norm_target in norm_name:
                score = 75.0
            elif norm_name in norm_target:
                score = 70.0
            elif norm_target in norm_keywords:
                score = 65.0
            elif norm_target in norm_exec_bin:
                score = 60.0
            else:
                sim = max(
                    difflib.SequenceMatcher(None, norm_target, norm_name).ratio(),
                    difflib.SequenceMatcher(None, norm_target, norm_file).ratio(),
                )
                if sim >= 0.6:
                    score = sim * 55.0

            if score >= 70.0:
                candidates.append((score, app))

        # Check for ambiguity: multiple unique application names with high scores
        unique_candidates = {}
        for score, app in sorted(candidates, key=lambda x: x[0], reverse=True):
            if app["name"] not in unique_candidates:
                unique_candidates[app["name"]] = (score, app)

        if len(unique_candidates) > 1:
            top_name, (top_score, top_app) = next(iter(unique_candidates.items()))
            second_name, (second_score, second_app) = list(unique_candidates.items())[1]

            # Ambiguity occurs when top two are close or both contain search query
            if (top_score - second_score) <= 15.0 or (norm_target in normalize_text(top_name) and norm_target in normalize_text(second_name)):
                matching_names = [f"'{name}'" for name in list(unique_candidates.keys())[:5]]
                res = (
                    f"Ambiguous application request: Found multiple applications matching '{app_name}': {', '.join(matching_names)}. "
                    f"Do not launch any app yet. Ask the user which specific application they would like to launch."
                )
                emit({"type": "tool_done", "name": "launch_app", "preview": res})
                return res

        if unique_candidates:
            best_app = next(iter(unique_candidates.values()))[1]
        else:
            best_app = None

    if not best_app:
        res = f"Could not find any installed application matching '{app_name}'."
        emit({"type": "tool_done", "name": "launch_app", "preview": res})
        return res

    # Clean field codes from Exec command (e.g. %u, %U, %f, %F, --uri=%u)
    exec_str = best_app["exec"]
    exec_str = re.sub(r'--\S*?=%[a-zA-Z]', '', exec_str)
    exec_str = re.sub(r'%[a-zA-Z]', '', exec_str).strip()

    cmd_parts = shlex.split(exec_str)
    if not cmd_parts:
        res = f"Error parsing Exec line for {best_app['name']}."
        emit({"type": "tool_done", "name": "launch_app", "preview": res})
        return res

    if best_app.get("terminal"):
        terminal_bin = shutil.which("kitty") or "kitty"
        launch_cmd = [terminal_bin, "-e"] + cmd_parts
    else:
        launch_cmd = cmd_parts

    try:
        subprocess.Popen(
            launch_cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL,
            start_new_session=True,
        )
        res = f"Successfully launched {best_app['name']}."
        emit({"type": "tool_done", "name": "launch_app", "preview": res})
        return res
    except Exception as e:
        res = f"Failed to launch {best_app['name']}: {e}"
        emit({"type": "tool_done", "name": "launch_app", "preview": res})
        return res

def perform_spotify_control(action: str, query: str = None) -> str:
    emit({"type": "tool_start", "name": "spotify_control", "args": {"action": action, "query": query}})
    action = (action or "").strip().lower()
    playerctl_bin = shutil.which("playerctl") or "/usr/bin/playerctl"

    if action == "status":
        for player_args in [["--player=spotify"], []]:
            try:
                res_status = subprocess.run(
                    [playerctl_bin, *player_args, "status"],
                    capture_output=True, text=True, timeout=2
                )
                if res_status.returncode == 0:
                    status_text = res_status.stdout.strip()
                    res_meta = subprocess.run(
                        [playerctl_bin, *player_args, "metadata", "--format", "{{title}} - {{artist}} ({{album}})"],
                        capture_output=True, text=True, timeout=2
                    )
                    meta_text = res_meta.stdout.strip() if res_meta.returncode == 0 else ""
                    res = f"Spotify Status: {status_text} | {meta_text}" if meta_text else f"Spotify Status: {status_text}"
                    emit({"type": "tool_done", "name": "spotify_control", "preview": res})
                    return res
            except Exception:
                pass
        res = "Spotify is not running or no track is active."
        emit({"type": "tool_done", "name": "spotify_control", "preview": res})
        return res

    elif action == "search_play":
        if not query or not query.strip():
            res = "Search query is required for search_play action."
            emit({"type": "tool_done", "name": "spotify_control", "preview": res})
            return res
        search_query = query.strip()
        uri = f"spotify:search:{urllib.parse.quote(search_query)}"
        opened = False
        try:
            p = subprocess.run([playerctl_bin, "--player=spotify", "open", uri], capture_output=True, text=True, timeout=3)
            if p.returncode == 0:
                opened = True
        except Exception:
            pass

        if not opened:
            spotify_bin = shutil.which("spotify") or "spotify"
            try:
                subprocess.Popen(
                    [spotify_bin, f"spotify:search:{search_query}"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    stdin=subprocess.DEVNULL,
                    start_new_session=True,
                )
                opened = True
            except Exception as e:
                res = f"Failed to search and play '{search_query}' on Spotify: {e}"
                emit({"type": "tool_done", "name": "spotify_control", "preview": res})
                return res

        res = f"Searching and playing '{search_query}' on Spotify."
        emit({"type": "tool_done", "name": "spotify_control", "preview": res})
        return res

    action_map = {
        "play": "play",
        "pause": "pause",
        "play_pause": "play-pause",
        "next": "next",
        "previous": "previous",
    }
    mpris_cmd = action_map.get(action)
    if not mpris_cmd:
        res = f"Unknown Spotify action '{action}'."
        emit({"type": "tool_done", "name": "spotify_control", "preview": res})
        return res

    try:
        p = subprocess.run([playerctl_bin, "--player=spotify", mpris_cmd], capture_output=True, text=True, timeout=3)
        if p.returncode != 0:
            p = subprocess.run([playerctl_bin, mpris_cmd], capture_output=True, text=True, timeout=3)

        if p.returncode == 0:
            res = f"Spotify action '{action}' completed."
        else:
            err = p.stderr.strip() or "Player not responding."
            res = f"Spotify action '{action}' failed: {err}"
    except Exception as e:
        res = f"Error executing Spotify action '{action}': {e}"

    emit({"type": "tool_done", "name": "spotify_control", "preview": res})
    return res

def perform_check_ai_quotas(provider: str = None) -> str:
    emit({"type": "tool_start", "name": "check_ai_quotas", "args": {"provider": provider}})
    codexbar_bin = shutil.which("codexbar") or "/home/linuxbrew/.linuxbrew/bin/codexbar"
    if not os.path.exists(codexbar_bin):
        res = "Error: codexbar binary not found on system."
        emit({"type": "tool_done", "name": "check_ai_quotas", "preview": res})
        return res

    cmd = [codexbar_bin, "usage", "--json"]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        if proc.returncode != 0 or not proc.stdout.strip():
            res = f"Error querying codexbar: {proc.stderr.strip() or 'No output'}"
            emit({"type": "tool_done", "name": "check_ai_quotas", "preview": res})
            return res

        data = json.loads(proc.stdout)
        lines = []
        for item in data:
            prov = item.get("provider", "unknown")
            if provider and provider.strip().lower() not in prov.lower():
                continue
            usage = item.get("usage", {})
            email = usage.get("accountEmail") or item.get("identity", {}).get("accountEmail", "")
            header = f"### Provider: {prov.capitalize()}" + (f" ({email})" if email else "")
            lines.append(header)

            labels = item.get("rateWindowLabels", {})
            extra = usage.get("extraRateWindows")
            if extra and isinstance(extra, list):
                for ew in extra:
                    title = ew.get("title", "Quota")
                    w = ew.get("window", {})
                    used = w.get("usedPercent", 0)
                    rem = max(0.0, 100.0 - float(used))
                    reset_desc = w.get("resetDescription") or ""
                    desc_str = f" (Resets: {reset_desc})" if reset_desc else ""
                    lines.append(f"- {title}: {rem:.1f}% remaining ({used:.1f}% used){desc_str}")
            else:
                primary = usage.get("primary")
                if primary and isinstance(primary, dict):
                    p_label = labels.get("primary", "Primary window")
                    used = primary.get("usedPercent", 0)
                    rem = max(0.0, 100.0 - float(used))
                    reset_desc = primary.get("resetDescription") or ""
                    desc_str = f" (Resets: {reset_desc})" if reset_desc else ""
                    lines.append(f"- {p_label}: {rem:.1f}% remaining ({used:.1f}% used){desc_str}")

                secondary = usage.get("secondary")
                if secondary and isinstance(secondary, dict):
                    s_label = labels.get("secondary", "Secondary window")
                    used = secondary.get("usedPercent", 0)
                    rem = max(0.0, 100.0 - float(used))
                    reset_desc = secondary.get("resetDescription") or ""
                    desc_str = f" (Resets: {reset_desc})" if reset_desc else ""
                    lines.append(f"- {s_label}: {rem:.1f}% remaining ({used:.1f}% used){desc_str}")

            credits_obj = usage.get("codexResetCredits")
            if credits_obj and isinstance(credits_obj, dict):
                avail = credits_obj.get("availableCount", 0)
                if avail:
                    lines.append(f"- Reset credits available: {avail}")

            lines.append("")

        res = "\n".join(lines).strip() or f"No quota data found for provider '{provider}'."
        preview = res[:100] + "..." if len(res) > 100 else res
        emit({"type": "tool_done", "name": "check_ai_quotas", "preview": preview})
        return res
    except Exception as e:
        res = f"Error reading AI quotas: {e}"
        emit({"type": "tool_done", "name": "check_ai_quotas", "preview": res})
        return res

def perform_web_search(query):
    emit({"type": "tool_start", "name": "web_search", "args": {"query": query}})
    try:
        url = "https://html.duckduckgo.com/html/?q=" + urllib.parse.quote(query)
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (X11; Linux x86_64)"})
        with urllib.request.urlopen(req) as response:
            html = response.read().decode('utf-8', errors='ignore')
        
        snippets = []
        titles = re.findall(r'<h2 class="result__title">.*?<a[^>]*>(.*?)</a>', html, re.DOTALL | re.IGNORECASE)
        texts = re.findall(r'<a class="result__snippet[^>]*>(.*?)</a>', html, re.DOTALL | re.IGNORECASE)
        
        clean_re = re.compile('<.*?>')
        for i in range(min(4, len(titles), len(texts))):
            t = re.sub(clean_re, '', titles[i]).strip()
            s = re.sub(clean_re, '', texts[i]).strip()
            snippets.append(f"Title: {t}\nSnippet: {s}")
            
        res = "\n\n".join(snippets) if snippets else "No results found."
        emit({"type": "tool_done", "name": "web_search", "preview": res[:100] + "..." if len(res)>100 else res})
        return res
    except Exception as e:
        emit({"type": "tool_done", "name": "web_search", "preview": f"Error: {e}"})
        return f"Error: {e}"

def perform_read_file(path):
    emit({"type": "tool_start", "name": "read_file", "args": {"path": path}})
    expanded_path = os.path.expanduser(path)
    try:
        with open(expanded_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read(4000)
            lines = content.split('\n')
            if len(lines) > 80:
                content = '\n'.join(lines[:80]) + '\n... (truncated)'
        emit({"type": "tool_done", "name": "read_file", "preview": content[:100] + "..." if len(content)>100 else content})
        return content
    except Exception as e:
        emit({"type": "tool_done", "name": "read_file", "preview": f"Error: {e}"})
        return f"Error: {e}"

def perform_list_dir(path):
    emit({"type": "tool_start", "name": "list_dir", "args": {"path": path}})
    expanded_path = os.path.expanduser(path)
    try:
        entries = os.listdir(expanded_path)
        out = []
        for i, entry in enumerate(entries[:40]):
            full_path = os.path.join(expanded_path, entry)
            if os.path.isdir(full_path):
                out.append(f"[DIR] {entry}")
            else:
                try:
                    size = os.stat(full_path).st_size
                    out.append(f"[FILE] {entry} ({size} bytes)")
                except:
                    out.append(f"[FILE] {entry}")
        if len(entries) > 40:
            out.append("... (truncated)")
        res = "\n".join(out)
        emit({"type": "tool_done", "name": "list_dir", "preview": res[:100] + "..." if len(res)>100 else res})
        return res
    except Exception as e:
        emit({"type": "tool_done", "name": "list_dir", "preview": f"Error: {e}"})
        return f"Error: {e}"

def call_llm(messages, use_tools=True, stream=True):
    ensure_llama_server_running()
    payload = {
        "model": MODEL,
        "messages": messages,
        "stream": stream
    }
    if use_tools:
        payload["tools"] = TOOLS
        
    req = urllib.request.Request(ENDPOINT, data=json.dumps(payload).encode('utf-8'), headers={"Content-Type": "application/json"})
    
    if not stream:
        try:
            with urllib.request.urlopen(req) as response:
                return json.loads(response.read().decode('utf-8'))
        except urllib.error.URLError as e:
            emit({"type": "error", "message": f"LLM error: {e}"})
            sys.exit(1)
            
    try:
        response = urllib.request.urlopen(req)
    except urllib.error.URLError as e:
        emit({"type": "error", "message": f"LLM error: {e}"})
        sys.exit(1)
        
    full_text = ""
    for line_bytes in response:
        line = line_bytes.decode('utf-8').strip()
        if not line or not line.startswith("data: "):
            continue
        data_str = line[6:]
        if data_str == "[DONE]":
            break
            
        try:
            chunk = json.loads(data_str)
            delta = chunk["choices"][0].get("delta", {})
            if "content" in delta and delta["content"]:
                content = delta["content"]
                full_text += content
                emit({"type": "token", "content": content})
        except json.JSONDecodeError:
            pass
            
    return full_text, None

def check_is_model_loaded(model_id=MODEL):
    try:
        req = urllib.request.Request("http://127.0.0.1:8090/v1/models")
        with urllib.request.urlopen(req, timeout=1.0) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            for m in data.get("data", []):
                if m.get("id") == model_id:
                    status_info = m.get("status", {})
                    val = status_info.get("value") if isinstance(status_info, dict) else status_info
                    return val == "loaded"
    except Exception:
        pass
    return False

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompt", type=str, help="User prompt")
    parser.add_argument("--context", type=str, help="Optional context", default="")
    parser.add_argument("--reset", action="store_true", help="Reset session")
    parser.add_argument("--clear", action="store_true", help="Clear session and exit")
    parser.add_argument("--warmup", action="store_true", help="Warm up model in RAM")
    args = parser.parse_args()

    if args.clear:
        if os.path.exists(SESSION_FILE):
            os.remove(SESSION_FILE)
        emit({"type": "cleared"})
        sys.exit(0)

    if args.warmup:
        try:
            if check_is_model_loaded(MODEL):
                emit({"type": "already_loaded"})
                sys.exit(0)
            emit({"type": "status", "message": "Warming up model..."})
            call_llm([{"role": "user", "content": "hi"}], use_tools=False, stream=False)
            emit({"type": "warmed_up"})
        except Exception as e:
            emit({"type": "warmup_error", "message": str(e)})
        sys.exit(0)
        
    if not args.prompt:
        sys.exit(0)
        
    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    
    if args.reset:
        if os.path.exists(SESSION_FILE):
            os.remove(SESSION_FILE)
    else:
        if os.path.exists(SESSION_FILE):
            try:
                with open(SESSION_FILE, 'r') as f:
                    history = json.load(f)
                    messages.extend(history)
            except:
                pass
                
    user_msg = args.prompt
    if args.context:
        user_msg = f"{args.context}\n\n{args.prompt}"
        
    messages.append({"role": "user", "content": user_msg})
    
    if not check_is_model_loaded(MODEL):
        emit({"type": "status", "message": "Warming up model..."})
    else:
        emit({"type": "status", "message": "Thinking..."})
    
    first_response = call_llm(messages, use_tools=True, stream=False)
    
    msg = first_response["choices"][0]["message"]
    
    if "tool_calls" in msg and msg["tool_calls"]:
        messages.append(msg)
        for tc in msg["tool_calls"]:
            func_name = tc["function"]["name"]
            try:
                func_args = json.loads(tc["function"]["arguments"])
            except:
                func_args = {}
                
            res_str = ""
            if func_name == "web_search":
                res_str = perform_web_search(func_args.get("query", ""))
            elif func_name == "read_file":
                res_str = perform_read_file(func_args.get("path", ""))
            elif func_name == "list_dir":
                res_str = perform_list_dir(func_args.get("path", ""))
            elif func_name == "list_desktop_apps":
                res_str = perform_list_desktop_apps(func_args.get("filter", None))
            elif func_name == "launch_app":
                res_str = perform_launch_app(func_args.get("app_name", ""))
            elif func_name == "spotify_control":
                res_str = perform_spotify_control(func_args.get("action", ""), func_args.get("query", None))
            elif func_name == "check_ai_quotas":
                res_str = perform_check_ai_quotas(func_args.get("provider", None))
            else:
                res_str = f"Unknown tool {func_name}"
                
            messages.append({
                "role": "tool",
                "tool_call_id": tc["id"],
                "content": res_str
            })
            
        emit({"type": "status", "message": "Synthesizing answer..."})
        full_text, _ = call_llm(messages, use_tools=False, stream=True)
        messages.append({"role": "assistant", "content": full_text})
        emit({"type": "done", "full_text": full_text})
    else:
        content = msg.get("content", "")
        emit({"type": "token", "content": content})
        messages.append({"role": "assistant", "content": content})
        emit({"type": "done", "full_text": content})
        
    history_to_save = messages[1:]
    if len(history_to_save) > 10:
        history_to_save = history_to_save[-10:]
        
    try:
        with open(SESSION_FILE, 'w') as f:
            json.dump(history_to_save, f)
    except:
        pass

    schedule_llama_idle_timer()

if __name__ == "__main__":
    main()

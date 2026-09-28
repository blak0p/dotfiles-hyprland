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
import unicodedata

SESSION_FILE = "/tmp/quickshell_island_ai_session.json"
ENDPOINT = "http://127.0.0.1:8090/v1/chat/completions"
MODEL = "gemma-4"

SYSTEM_PROMPT = """You are a lightning-fast, concise desktop assistant embedded in a Hyprland Linux Dynamic Island.
You have access to tools for live web search, local filesystem inspection, launching desktop applications, controlling Spotify playback, and starting coding sessions.
IMPORTANT: Detect the user's language and ALWAYS answer in the exact same language (e.g., Spanish if asked in Spanish).
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
            "name": "start_coding_session",
            "description": "Initiates a coding session in a project directory using herdr and a coding agent (default: pi).",
            "parameters": {
                "type": "object",
                "properties": {
                    "project_name": {
                        "type": "string",
                        "description": "Name of the project folder in ~/dev/ to work on."
                    },
                    "agent": {
                        "type": "string",
                        "description": "Coding agent to launch, e.g. 'pi' (default: 'pi')."
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

    best_app = None
    best_score = -1.0

    for app in apps:
        score = 0.0
        norm_name = normalize_text(app["name"])
        norm_file = normalize_text(os.path.splitext(app["file"])[0])
        norm_exec_bin = normalize_text(app["exec"].split()[0] if app["exec"] else "")
        norm_generic = normalize_text(app.get("generic_name", ""))
        norm_keywords = normalize_text(app.get("keywords", ""))

        if norm_target in (norm_name, norm_file, norm_exec_bin):
            score = 100.0
        elif norm_target in norm_generic:
            score = 90.0
        elif norm_target in norm_name:
            score = 80.0 + (len(norm_target) / max(len(norm_name), 1)) * 10
        elif norm_name in norm_target:
            score = 75.0
        elif norm_target in norm_keywords:
            score = 70.0
        elif norm_target in norm_exec_bin:
            score = 60.0
        else:
            sim = max(
                difflib.SequenceMatcher(None, norm_target, norm_name).ratio(),
                difflib.SequenceMatcher(None, norm_target, norm_file).ratio(),
            )
            if sim >= 0.6:
                score = sim * 55.0

        if score > best_score:
            best_score = score
            best_app = app

    if not best_app or best_score < 30.0:
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

def perform_start_coding_session(project_name: str = None, agent: str = "pi") -> str:
    emit({"type": "tool_start", "name": "start_coding_session", "args": {"project_name": project_name, "agent": agent}})
    dev_root = os.path.expanduser("~/dev")
    if not os.path.exists(dev_root):
        dev_root = "/home/alejandro/dev"

    subdirs = []
    if os.path.exists(dev_root):
        try:
            subdirs = sorted([
                d for d in os.listdir(dev_root)
                if os.path.isdir(os.path.join(dev_root, d)) and not d.startswith(".")
            ])
        except Exception:
            subdirs = []

    if not project_name or not project_name.strip():
        listing = ", ".join(subdirs) if subdirs else "none found"
        res = f"Please specify which project in ~/dev/ you would like to work on. Available projects:\n{listing}"
        emit({"type": "tool_done", "name": "start_coding_session", "preview": "Awaiting project selection"})
        return res

    target_query = project_name.strip()
    matched_dir = None

    # 1. Exact match (case insensitive)
    for d in subdirs:
        if d.lower() == target_query.lower():
            matched_dir = d
            break

    # 2. Substring match
    if not matched_dir:
        for d in subdirs:
            if target_query.lower() in d.lower():
                matched_dir = d
                break

    # 3. Fuzzy match
    if not matched_dir:
        best_ratio = 0.0
        best_cand = None
        for d in subdirs:
            ratio = difflib.SequenceMatcher(None, target_query.lower(), d.lower()).ratio()
            if ratio > best_ratio and ratio >= 0.5:
                best_ratio = ratio
                best_cand = d
        if best_cand:
            matched_dir = best_cand

    if not matched_dir:
        res = f"Project '{project_name}' not found in ~/dev/. Available projects: {', '.join(subdirs)}"
        emit({"type": "tool_done", "name": "start_coding_session", "preview": res})
        return res

    project_path = os.path.join(dev_root, matched_dir)
    chosen_agent = (agent or "pi").strip()

    herdr_bin = "/home/linuxbrew/.linuxbrew/bin/herdr"
    pi_bin = "/home/linuxbrew/.linuxbrew/bin/pi"
    kitty_bin = shutil.which("kitty") or "/usr/bin/kitty"

    if chosen_agent.lower() in ("herdr", "pi"):
        target_bin = herdr_bin if os.path.exists(herdr_bin) else (pi_bin if os.path.exists(pi_bin) else shutil.which("herdr") or shutil.which("pi") or "herdr")
    else:
        target_bin = shutil.which(chosen_agent) or (f"/home/linuxbrew/.linuxbrew/bin/{chosen_agent}" if os.path.exists(f"/home/linuxbrew/.linuxbrew/bin/{chosen_agent}") else herdr_bin)

    cmd = [kitty_bin, "--directory", project_path, target_bin]
    try:
        subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL,
            start_new_session=True,
        )
        res = f"Started coding session for '{matched_dir}' with agent '{chosen_agent}' in {project_path}."
        emit({"type": "tool_done", "name": "start_coding_session", "preview": res})
        return res
    except Exception as e:
        res = f"Failed to start coding session in {project_path}: {e}"
        emit({"type": "tool_done", "name": "start_coding_session", "preview": res})
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
            elif func_name == "launch_app":
                res_str = perform_launch_app(func_args.get("app_name", ""))
            elif func_name == "spotify_control":
                res_str = perform_spotify_control(func_args.get("action", ""), func_args.get("query", None))
            elif func_name == "start_coding_session":
                res_str = perform_start_coding_session(func_args.get("project_name", None), func_args.get("agent", "pi"))
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

if __name__ == "__main__":
    main()

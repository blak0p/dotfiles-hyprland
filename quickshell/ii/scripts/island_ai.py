import os
import sys
import json
import urllib.request
import urllib.parse
import urllib.error
import argparse
import re

SESSION_FILE = "/tmp/quickshell_island_ai_session.json"
ENDPOINT = "http://127.0.0.1:8090/v1/chat/completions"
MODEL = "gemma-4"

SYSTEM_PROMPT = """You are a lightning-fast, concise desktop assistant embedded in a Hyprland Linux Dynamic Island.
You have access to tools for live web search and local filesystem inspection.
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
    }
]

def emit(data):
    print(json.dumps(data), flush=True)

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

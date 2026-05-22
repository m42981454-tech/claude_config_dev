#!/usr/bin/env python3
# Render claude-hud output into the three-line Claude statusline.
import sys, re, os, json
from collections import deque
from pathlib import Path
from datetime import datetime, timezone
sys.stdin.reconfigure(encoding="utf-8", newline="\n")
sys.stdout.reconfigure(encoding="utf-8", newline="\n")

ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")
MAGENTA = "\x1b[35m"
SEP = " │ "  # space U+2502 space

RESET  = "\x1b[0m"
BOLD   = "\x1b[1m"
DIM    = "\x1b[2m"
CYAN   = "\x1b[36m"
GREEN  = "\x1b[32m"
RED    = "\x1b[31m"
YELLOW = "\x1b[33m"
GREY   = "\x1b[90m"
FG_WHITE   = "\x1b[97m"

AGENT_BG = {
    "cyan":   "\x1b[106m",   # bright cyan
    "blue":   "\x1b[104m",   # bright blue
    "purple": "\x1b[105m",   # bright magenta
    "orange": "\x1b[103m",   # bright yellow
    "slate":  "\x1b[100m",   # bright black (dark gray)
    "red":    "\x1b[101m",   # bright red
    "green":  "\x1b[102m",   # bright green
}
AGENT_KEYWORDS = {
    "orchestrator":   "cyan",
    "backend":        "blue",
    "code reviewer":  "purple",
    "frontend":       "cyan",
    "git workflow":   "orange",
    "minimal":        "slate",
    "project manager":"blue",
    "reality":        "red",
    "security":       "red",
    "tester":         "green",
    "api tester":     "green",
    "evidence":       "green",
    "sre":            "orange",
    "devops":         "orange",
    "incident":       "red",
    "database":       "blue",
    "ai engineer":    "purple",
    "data engineer":  "purple",
}

def agent_bg_color(text):
    t = text.lower()
    for kw, color in AGENT_KEYWORDS.items():
        if kw in t:
            return AGENT_BG.get(color, "\x1b[105m")
    return "\x1b[105m"

def read_active_agent_from_transcript():
    """Return (name, elapsed_seconds) of active agent, or (None, 0)."""
    path = os.environ.get("TRANSCRIPT_PATH", "")
    if not path or not Path(path).exists():
        return None, 0
    try:
        with open(path, encoding="utf-8") as f:
            lines = deque(f, maxlen=300)
    except Exception:
        return None, 0
    pending = {}     # tool_use_id -> (subagent_type, ts_str)
    completed = set()
    for ln in lines:
        try:
            evt = json.loads(ln)
        except Exception:
            continue
        msg = evt.get("message", {})
        if not isinstance(msg, dict):
            continue
        content = msg.get("content", [])
        if not isinstance(content, list):
            continue
        for c in content:
            if not isinstance(c, dict):
                continue
            ctype = c.get("type")
            if ctype == "tool_use" and c.get("name") in ("Task", "Agent"):
                tu_id = c.get("id")
                inp = c.get("input", {}) or {}
                subagent = inp.get("subagent_type") or inp.get("description") or "Agent"
                if tu_id:
                    pending[tu_id] = (subagent, evt.get("timestamp", ""))
            elif ctype == "tool_result":
                tu_id = c.get("tool_use_id")
                if tu_id:
                    completed.add(tu_id)
    # Find most recent pending Task
    actives = [(tu_id, sub, ts) for tu_id, (sub, ts) in pending.items() if tu_id not in completed]
    if not actives:
        return None, 0
    actives.sort(key=lambda x: x[2], reverse=True)
    _, sub, ts = actives[0]
    elapsed = 0
    if ts:
        try:
            start = datetime.fromisoformat(ts.replace("Z", "+00:00"))
            elapsed = int((datetime.now(timezone.utc) - start).total_seconds())
        except Exception:
            pass
    return sub, elapsed

def strip_ansi(s):
    return ANSI_RE.sub("", s)

def colorize_git(s):
    s = re.sub(r"(\+\d+)",  YELLOW + r"\1" + RESET, s)
    s = re.sub(r"(~\d+)",   RED    + r"\1" + RESET, s)
    s = re.sub(r"(\?\d+)",  GREY   + r"\1" + RESET, s)
    s = re.sub(r"(✚\d+)",  GREEN  + r"\1" + RESET, s)
    s = re.sub(r"(↓\d+)",   RED    + r"\1" + RESET, s)
    s = re.sub(r"\blocal\b", YELLOW + "local" + RESET, s)
    s = re.sub(r"(\([^)]+\))", DIM + r"\1" + RESET, s)
    s = re.sub(r"(\"[^\"]+" + "…" + r"?\")", DIM + r"\1" + RESET, s)
    return s

identity, tools_todos, agents = [], [], []
state = "identity"
last_bucket = None

cwd_label = os.environ.get("CWD_LABEL", "")
if cwd_label:
    identity.append(f"{BOLD}{CYAN}{cwd_label}{RESET}")

for raw_line in sys.stdin.read().splitlines():
    plain = strip_ansi(raw_line).lstrip()
    if not plain:
        continue
    starts_activity = plain[:1] in ("◐", "✓", "▸")  # ◐ ✓ ▸
    if starts_activity:
        state = "activity"
        if MAGENTA in raw_line:
            agents.append(raw_line)
            last_bucket = "agents"
        else:
            tools_todos.append(raw_line)
            last_bucket = "tools_todos"
    elif state == "identity":
        identity.append(raw_line)
    else:
        if last_bucket == "agents" and agents:
            agents[-1] += " " + raw_line.strip()
        elif tools_todos:
            tools_todos[-1] += " " + raw_line.strip()
        else:
            identity.append(raw_line)

reset_conf = Path.home() / ".claude" / "reset-date.conf"
reset_date = reset_conf.read_text().strip() if reset_conf.exists() else ""

tok_lines, usage_lines, identity_main = [], [], []
for item in identity:
    plain_item = strip_ansi(item)
    if "tok:" in plain_item or "⏱" in plain_item:
        tok_lines.append(item)
    elif "用量" in plain_item or "本周" in plain_item or "█" in plain_item or "░" in plain_item:
        usage_item = item.replace("用量", "Sess").replace("本周", "Week")
        usage_lines.append(usage_item)
    else:
        identity_main.append(item)

if reset_date and usage_lines:
    new_usage = []
    for item in usage_lines:
        plain_item = strip_ansi(item)
        if "Week" in plain_item:
            item = item.rstrip() + " →" + reset_date
        new_usage.append(item)
    usage_lines = new_usage

git_suffix = colorize_git(os.environ.get("GIT_INFO", "").strip())
if git_suffix:
    for i, item in enumerate(identity_main):
        if "git:(" in strip_ansi(item):
            identity_main[i] = item.rstrip() + " " + git_suffix
            break

out = []
if identity_main:
    out.append(SEP.join(identity_main))

line2_parts = usage_lines + tok_lines
if line2_parts: out.append(SEP.join(line2_parts))

line3_parts = []

# Transcript-based active agent detection (independent of claude-hud output)
active_name, active_elapsed = read_active_agent_from_transcript()
if active_name:
    bg = agent_bg_color(active_name)
    elapsed_str = f" [{active_elapsed}s]" if active_elapsed > 0 else ""
    agent_block = f"{bg}{FG_WHITE}{BOLD}  ⚡ AGENT: {active_name}{elapsed_str} ⚡  {RESET}"
    line3_parts.append(agent_block)

# Tools/todos activity from claude-hud（不再显示 claude-hud agents bucket
# 历史已完成 agent，避免与 transcript-based 当前活跃块冗余）
line3_parts.extend(tools_todos)

if line3_parts: out.append(SEP.join(line3_parts))
sys.stdout.write("\n".join(out) + "\n")
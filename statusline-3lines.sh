#!/bin/bash
# Wrap claude-hud, regroup output into 3 lines:
#   Line 1: identity/context/usage/git (all non-activity lines merged with " │ ")
#   Line 2: tools + todos activity merged
#   Line 3: subagent activity merged (alone)
# Preserves ANSI color codes verbatim.

input=$(cat)

plugin_dir=$(ls -d "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/plugins/cache/claude-hud/claude-hud/*/ 2>/dev/null \
  | awk -F/ '{ print $(NF-1) "\t" $0 }' \
  | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n \
  | tail -1 \
  | cut -f2-)

if [ -z "$plugin_dir" ] || [ ! -f "${plugin_dir}dist/index.js" ]; then
  echo "claude-hud not found in cache" >&2
  exit 0
fi

# Run claude-hud and let Python regroup
export CWD_LABEL
CWD_LABEL="$(basename "$PWD")"
export PYTHONIOENCODING=utf-8
export PYTHONUTF8=1
printf '%s' "$input" | /c/nvm4w/nodejs/node "${plugin_dir}dist/index.js" \
  | /c/Users/dev002/miniconda3/python -c '
import sys, re, os
from pathlib import Path
sys.stdin.reconfigure(encoding="utf-8", newline="\n")
sys.stdout.reconfigure(encoding="utf-8", newline="\n")

ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")
MAGENTA = "\x1b[35m"
SEP = " │ "  # space U+2502 space

def strip_ansi(s):
    return ANSI_RE.sub("", s)

identity, tools_todos, agents = [], [], []
state = "identity"
last_bucket = None

cwd_label = os.environ.get("CWD_LABEL", "")
if cwd_label:
    identity.append(cwd_label)

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

out = []
if identity:
    line = SEP.join(identity)
    line = line.replace("用量", "Sess").replace("本周", "Week")
    if reset_date:
        idx = line.find("Week")
        if idx != -1:
            next_sep = line.find(SEP, idx)
            if next_sep != -1:
                line = line[:next_sep] + " →" + reset_date + line[next_sep:]
            else:
                line = line + " →" + reset_date
    out.append(line)
if tools_todos: out.append(SEP.join(tools_todos))
if agents:      out.append(SEP.join(agents))
sys.stdout.write("\n".join(out) + "\n")
'

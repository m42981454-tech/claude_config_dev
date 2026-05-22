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

export GIT_INFO
GIT_INFO=""
if git -C "$PWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # dirty status
    _porcelain=$(git -C "$PWD" status --porcelain 2>/dev/null)
    _staged=$(printf '%s\n' "$_porcelain" | awk '/^[MADRC]/{c++} END{print c+0}')
    _unstaged=$(printf '%s\n' "$_porcelain" | awk '/^.[MD]/{c++} END{print c+0}')
    _untracked=$(printf '%s\n' "$_porcelain" | awk '/^\?\?/{c++} END{print c+0}')
    [ "$_staged"    -gt 0 ] && GIT_INFO="${GIT_INFO} +${_staged}"
    [ "$_unstaged"  -gt 0 ] && GIT_INFO="${GIT_INFO} ~${_unstaged}"
    [ "$_untracked" -gt 0 ] && GIT_INFO="${GIT_INFO} ?${_untracked}"

    # ahead/behind or local-only
    _upstream=$(git -C "$PWD" rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    if [ -n "$_upstream" ]; then
        _ahead=$(git -C "$PWD" rev-list "${_upstream}..HEAD" --count 2>/dev/null || echo 0)
        _behind=$(git -C "$PWD" rev-list "HEAD..${_upstream}" --count 2>/dev/null || echo 0)
        [ "$_ahead"  -gt 0 ] && GIT_INFO="${GIT_INFO} ✚${_ahead}"
        [ "$_behind" -gt 0 ] && GIT_INFO="${GIT_INFO} ↓${_behind}"
    else
        _local=$(git -C "$PWD" rev-list HEAD --count 2>/dev/null || echo 0)
        GIT_INFO="${GIT_INFO} local ✚${_local}"
    fi

    # total commits on branch + last commit info
    _total=$(git -C "$PWD" rev-list HEAD --count 2>/dev/null || echo 0)
    _hash=$(git -C "$PWD" rev-parse --short HEAD 2>/dev/null)
    _time=$(git -C "$PWD" log -1 --format="%ar" 2>/dev/null)
    _msg=$(git -C "$PWD" log -1 --format="%s" 2>/dev/null | cut -c1-38)
    GIT_INFO="${GIT_INFO} (${_total} commits) ${_hash} ${_time} \"${_msg}…\""
fi

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

RESET  = "\x1b[0m"
BOLD   = "\x1b[1m"
DIM    = "\x1b[2m"
CYAN   = "\x1b[36m"
GREEN  = "\x1b[32m"
RED    = "\x1b[31m"
YELLOW = "\x1b[33m"
GREY   = "\x1b[90m"

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

line3_parts = tools_todos[:] + agents[:]
if line3_parts: out.append(SEP.join(line3_parts))
sys.stdout.write("\n".join(out) + "\n")
'

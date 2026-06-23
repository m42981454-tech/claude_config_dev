#!/bin/bash
# Wrap claude-hud, regroup output into 3 lines:
#   Line 1: identity/context/usage/git (all non-activity lines merged with " │ ")
#   Line 2: tools + todos activity merged
#   Line 3: subagent activity merged (alone)
# Preserves ANSI color codes verbatim.

# === Force UTF-8 encoding throughout (fixes CP932/CP936 mojibake on Windows) ===
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
export LC_CTYPE=C.UTF-8
export PYTHONIOENCODING=utf-8
export PYTHONUTF8=1
# Windows cmd code page → UTF-8 (silent, fallback safe)
command -v chcp.com >/dev/null 2>&1 && chcp.com 65001 >/dev/null 2>&1 || true

input=$(cat)

resolve_cmd() {
  local env_value="$1"
  local fallback="$2"
  local command_name="$3"

  if [ -n "$env_value" ] && command -v "$env_value" >/dev/null 2>&1; then
    printf '%s' "$env_value"
    return 0
  fi

  if [ -n "$fallback" ] && [ -x "$fallback" ]; then
    printf '%s' "$fallback"
    return 0
  fi

  if command -v "$command_name" >/dev/null 2>&1; then
    command -v "$command_name"
    return 0
  fi

  return 1
}

if [ -n "${CLAUDE_HUD_PLUGIN_DIR:-}" ]; then
  plugin_dir="${CLAUDE_HUD_PLUGIN_DIR%/}/"
else
  plugin_dir=$(ls -d "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/plugins/cache/claude-hud/claude-hud/*/ 2>/dev/null \
    | awk -F/ '{ print $(NF-1) "\t" $0 }' \
    | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n \
    | tail -1 \
    | cut -f2-)
fi

if [ -z "$plugin_dir" ] || [ ! -f "${plugin_dir}dist/index.js" ]; then
  exit 0
fi

NODE_BIN=$(resolve_cmd "${CLAUDE_STATUS_NODE:-}" "/c/nvm4w/nodejs/node" "node") || exit 0
PYTHON_BIN=$(resolve_cmd "${CLAUDE_STATUS_PYTHON:-}" "/c/Users/dev002/miniconda3/python" "python3") || \
  PYTHON_BIN=$(resolve_cmd "${CLAUDE_STATUS_PYTHON:-}" "/c/Users/dev002/miniconda3/python" "python") || exit 0

# Run claude-hud and let Python regroup
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

export TRANSCRIPT_PATH
TRANSCRIPT_PATH=$(echo "$input" | jq -r '.transcript_path // ""' 2>/dev/null || echo "")

# Thinking/effort state lives in settings.json (static config), not in the
# stdin hook payload — read it directly so the statusline can show it.
export THINKING_ENABLED EFFORT_LEVEL
THINKING_ENABLED="true"
EFFORT_LEVEL=""
SETTINGS_FILE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
  _thinking=$(jq -r '.alwaysThinkingEnabled' "$SETTINGS_FILE" 2>/dev/null)
  [ "$_thinking" = "false" ] && THINKING_ENABLED="false"
  EFFORT_LEVEL=$(jq -r '.effortLevel // ""' "$SETTINGS_FILE" 2>/dev/null)
fi

export PYTHONIOENCODING=utf-8
export PYTHONUTF8=1
STATUSLINE_RENDERER="${CLAUDE_STATUS_RENDERER:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/scripts/statusline-render.py}"
if [ ! -f "$STATUSLINE_RENDERER" ]; then
  exit 0
fi

printf '%s' "$input" | "$NODE_BIN" "${plugin_dir}dist/index.js" \
  | "$PYTHON_BIN" "$STATUSLINE_RENDERER"

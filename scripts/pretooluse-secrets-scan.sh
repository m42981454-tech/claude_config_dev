#!/usr/bin/env bash
# PreToolUse hook: scan Edit/Write/NotebookEdit payloads for likely secrets before they hit disk.
# Protocol: https://code.claude.com/docs/en/hooks-guide (stdin JSON in, hookSpecificOutput JSON out)

# Scan the raw stdin JSON payload directly (content/new_string/cell_source live inside
# tool_input as JSON-escaped strings) instead of shelling out to python, whose shim is
# unreliable in this environment — grep over the raw blob still catches plaintext secrets.
content=$(cat)

[ -z "$content" ] && exit 0

patterns=(
  'AKIA[0-9A-Z]{16}'                                  # AWS access key
  'aws_secret_access_key'                             # AWS secret marker
  '-----BEGIN (RSA|OPENSSH|EC|DSA|PGP) PRIVATE KEY-----'
  'gh[pousr]_[A-Za-z0-9]{36,}'                         # GitHub tokens
  'sk-(ant|proj|live)?[A-Za-z0-9_-]{20,}'              # Anthropic/OpenAI/Stripe-style secret keys
  'xox[baprs]-[A-Za-z0-9-]{10,}'                       # Slack tokens
  'AIza[0-9A-Za-z_-]{35}'                              # Google API key
  '(password|passwd|secret|api[_-]?key|access[_-]?token)["\x27]?[[:space:]]*[:=][[:space:]]*["\x27][^"\x27[:space:]]{8,}["\x27]'
)

for p in "${patterns[@]}"; do
  if printf '%s' "$content" | grep -qiE -- "$p"; then
    cat <<JSON
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"检测到可能的密钥/凭据写入（匹配规则: $p），请确认后再继续。"}}
JSON
    exit 0
  fi
done

exit 0

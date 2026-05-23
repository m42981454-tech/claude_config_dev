#!/usr/bin/env bash
# Validate an initialized new-project template.
# Exit codes: 0=green, 1=errors, 2=warnings only.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 1

FORCE_MODE=false
for arg in "$@"; do
  case "$arg" in
    --force|-f) FORCE_MODE=true ;;
  esac
done

if [[ "$FORCE_MODE" = false && -f "project.env" ]]; then
  cat <<'EOF'
--- Claude Code Template Validator ---

project.env still exists, so this template has not been initialized.
Initialize first:
  - Claude Code: /project:init
  - Shell:       bash init.sh

Template maintainers can run: .claude/scripts/validate.sh --force
EOF
  exit 0
fi

errors=0
warnings=0
echo "--- Claude Code Template Validator ---"

required=(
  "CLAUDE.md"
  "progress.md"
  ".claude/settings.json"
  ".claude/rules/engineering.md"
  ".claude/rules/behavioral-rules.md"
  ".claude/rules/git-workflow.md"
  ".githooks/pre-commit"
  ".githooks/install.sh"
)

missing=()
for file in "${required[@]}"; do
  [[ -f "$file" ]] || missing+=("$file")
done

if [[ ${#missing[@]} -eq 0 ]]; then
  echo "OK required files exist"
else
  echo "ERROR missing required files:"
  printf '  %s\n' "${missing[@]}"
  errors=$((errors + 1))
fi

if command -v jq >/dev/null 2>&1; then
  echo "OK jq available"
else
  echo "ERROR jq is required for Claude Code Bash safety hooks"
  errors=$((errors + 1))
fi

scan_targets=(
  "CLAUDE.md"
  "progress.md"
  ".claude/rules/git-workflow.md"
  ".claude/rules/behavioral-rules.md"
  ".claude/rules/project-context.md"
  ".claude/rules/stack-backend.md"
  ".claude/rules/stack-frontend.md"
  ".claude/rules/README.md"
  ".githooks/pre-commit"
)

placeholder_hits=""
placeholder_count=0
placeholder_pattern='\[[A-Z][A-Z0-9_]+\]|\[[a-z]+-dir\]'
for file in "${scan_targets[@]}"; do
  [[ -f "$file" ]] || continue
  while IFS= read -r hit; do
    [[ -z "$hit" ]] && continue
    placeholder_hits+="  $file:$hit"$'\n'
    placeholder_count=$((placeholder_count + 1))
  done < <(grep -En "$placeholder_pattern" "$file" 2>/dev/null || true)
done

if [[ $placeholder_count -eq 0 ]]; then
  echo "OK no unresolved placeholders"
else
  echo "WARN unresolved placeholders found: $placeholder_count"
  printf '%s' "$placeholder_hits"
  warnings=$((warnings + 1))
fi

if [[ -d ".git" ]]; then
  hooks_path="$(git config core.hooksPath 2>/dev/null || true)"
  normalized="${hooks_path//\\//}"
  if [[ "$normalized" == ".githooks" || "$normalized" == */.githooks ]]; then
    echo "OK Git hooks installed"
  else
    echo "WARN Git hooks not installed. Run: bash .githooks/install.sh"
    warnings=$((warnings + 1))
  fi
else
  echo "INFO not a git repo; skipping hook installation check"
fi

leftovers=()
for file in "project.env" "init.sh" "SETUP.md"; do
  [[ -f "$file" ]] && leftovers+=("$file")
done

if [[ ${#leftovers[@]} -eq 0 ]]; then
  echo "OK initialization files cleaned"
else
  echo "WARN initialization files still present:"
  printf '  %s\n' "${leftovers[@]}"
  warnings=$((warnings + 1))
fi

broken_links=""
broken_count=0
if [[ -d ".claude/rules" ]]; then
  while IFS= read -r file; do
    dir="$(dirname "$file")"
    while IFS= read -r link; do
      [[ -z "$link" ]] && continue
      clean_link="${link%%#*}"
      [[ -z "$clean_link" ]] && continue
      if [[ ! -f "$dir/$clean_link" ]]; then
        broken_links+="  $file -> $clean_link"$'\n'
        broken_count=$((broken_count + 1))
      fi
    done < <(grep -oE '\]\((\.{1,2}/[^)]+\.md[^)]*|[a-zA-Z][^):/]*\.md[^)]*)\)' "$file" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//')
  done < <(find .claude/rules -maxdepth 1 -type f -name '*.md' | sort)
fi

if [[ $broken_count -eq 0 ]]; then
  echo "OK rule links valid"
else
  echo "ERROR broken rule links found: $broken_count"
  printf '%s' "$broken_links"
  errors=$((errors + 1))
fi

echo
echo "Result: $warnings warnings / $errors errors"
if [[ $errors -gt 0 ]]; then
  exit 1
elif [[ $warnings -gt 0 ]]; then
  exit 2
else
  exit 0
fi

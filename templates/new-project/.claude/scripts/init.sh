#!/usr/bin/env bash
# Initialize a new project from this template by replacing placeholders.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

ENV_FILE="project.env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE. Fill the template config first." >&2
  exit 1
fi

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

while IFS='=' read -r key value || [[ -n "${key:-}" ]]; do
  [[ "${key:-}" =~ ^[[:space:]]*# ]] && continue
  key="$(trim "${key:-}")"
  [[ -z "$key" ]] && continue
  value="${value%%#*}"
  value="$(trim "$value")"
  export "$key=$value"
done < "$ENV_FILE"

DATE="${DATE:-$(date +%Y-%m-%d)}"
REPO_SLUG="${REPO_OWNER:-owner}/${REPO_NAME:-repo}"

required_vars=(
  PROJECT_NAME PHASE MAIN_BRANCH BACKEND_DIR FRONTEND_DIR
  BACKEND_STACK FRONTEND_STACK INFRA
  BACKEND_LANGUAGE_VERSION BACKEND_FRAMEWORK ORM_AND_MIGRATIONS DATABASE
  TASK_QUEUE TEST_FRAMEWORK_BACKEND
  FRONTEND_FRAMEWORK FRONTEND_LANGUAGE STYLING STATE_MGMT I18N
  TEST_FRAMEWORK_FRONTEND REPO_OWNER REPO_NAME
)

missing=()
for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    missing+=("$var")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Missing required values in $ENV_FILE:" >&2
  printf '  %s\n' "${missing[@]}" >&2
  exit 1
fi

echo "Initializing $PROJECT_NAME on main branch $MAIN_BRANCH"

sub() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  replace "$file" "PROJECT_NAME" "$PROJECT_NAME"
  replace "$file" "PHASE" "$PHASE"
  replace "$file" "DATE" "$DATE"
  replace "$file" "MAIN_BRANCH" "$MAIN_BRANCH"
  replace "$file" "REPO_OWNER" "$REPO_OWNER"
  replace "$file" "REPO_NAME" "$REPO_NAME"
  replace "$file" "REPO" "$REPO_SLUG"
  replace "$file" "backend-dir" "$BACKEND_DIR"
  replace "$file" "frontend-dir" "$FRONTEND_DIR"
  replace "$file" "BACKEND_STACK" "$BACKEND_STACK"
  replace "$file" "FRONTEND_STACK" "$FRONTEND_STACK"
  replace "$file" "INFRA" "$INFRA"
  replace "$file" "BACKEND_LANGUAGE_VERSION" "$BACKEND_LANGUAGE_VERSION"
  replace "$file" "BACKEND_FRAMEWORK" "$BACKEND_FRAMEWORK"
  replace "$file" "ORM_AND_MIGRATIONS" "$ORM_AND_MIGRATIONS"
  replace "$file" "DATABASE" "$DATABASE"
  replace "$file" "TASK_QUEUE" "$TASK_QUEUE"
  replace "$file" "TEST_FRAMEWORK" "$TEST_FRAMEWORK_BACKEND"
  replace "$file" "FRONTEND_FRAMEWORK" "$FRONTEND_FRAMEWORK"
  replace "$file" "LANGUAGE" "$FRONTEND_LANGUAGE"
  replace "$file" "STYLING" "$STYLING"
  replace "$file" "STATE_MGMT" "$STATE_MGMT"
  replace "$file" "I18N" "$I18N"
  replace "$file" "TEST_FRAMEWORK_FRONTEND" "$TEST_FRAMEWORK_FRONTEND"
}

replace() {
  local file="$1"
  local placeholder="$2"
  local value="$3"
  local escaped
  escaped=$(printf '%s' "$value" | sed -e 's/[\\&|]/\\&/g')
  sed -i -e "s|\\[$placeholder\\]|$escaped|g" "$file"
}

targets=(
  CLAUDE.md
  progress.md
  .claude/rules/git-workflow.md
  .claude/rules/behavioral-rules.md
  .claude/rules/project-context.md
  .claude/rules/stack-backend.md
  .claude/rules/stack-frontend.md
  .claude/rules/README.md
  .githooks/pre-commit
)

for file in "${targets[@]}"; do
  sub "$file"
done

echo "Placeholder replacement complete."
echo
echo "Next steps:"
echo "1. Review .claude/rules/stack-backend.md and stack-frontend.md; delete unused rows."
echo "2. Review .claude/agents/.enabled for optional agents."
echo "3. If the project has no backend, delete .claude/rules/stack-backend.md."
echo "4. If the project has no frontend, delete .claude/rules/stack-frontend.md."
echo "5. Delete project.env and SETUP.md before the first project commit."
echo "6. Run .claude/scripts/validate.sh --force, or .claude/scripts/validate.ps1 -Force on Windows."

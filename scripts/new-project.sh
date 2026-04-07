#!/usr/bin/env bash
# new-project.sh — scaffold a new Pi-aware project with sensible defaults.
# Usage:
#   bash new-project.sh <project-name> [--type coding|knowledge|ops|minimal] [--no-git]
#
# Examples:
#   bash new-project.sh my-api
#   bash new-project.sh kb --type knowledge
#   bash new-project.sh infra --type ops --no-git

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates"
PROJECT_TYPE="coding"
NO_GIT=false
VERBOSE=false

# ── Helpers ───────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $(basename "$0") <project-name> [options]

Arguments:
  project-name          Name of the project directory to create.

Options:
  --type <type>         Project type: coding (default), knowledge, ops, minimal
  --no-git              Skip git init
  --verbose             Print created files
  -h, --help            Show this message
EOF
}

info()  { echo "[INFO]  $*" >&2; }
warn()  { echo "[WARN]  $*" >&2; }
die()   { echo "[ERROR] $*" >&2; exit 1; }

# Print a formatted tree of what was created.
report_tree() {
  local root="$1"
  echo ""
  echo "  $root/"
  _tree "$root" ""
}

_tree() {
  local dir="$1"
  local prefix="$2"
  local entries
  entries=$(ls -1d "$dir"/*/ 2>/dev/null || true)
  local first=true
  for entry in $entries; do
    entry="${entry%/}"
    local name
    name=$(basename "$entry")
    if $first; then
      echo "${prefix}├── $name/"
      first=false
    else
      echo "${prefix}│   $name/"
    fi
    _tree "$entry" "$prefix│   "
  done
  local files
  files=$(ls -1 "$dir"/* 2>/dev/null | grep -v "/$" || true)
  for file in $files; do
    local name
    name=$(basename "$file")
    if $first; then
      echo "${prefix}└── $name"
      first=false
    else
      echo "${prefix}    $name"
    fi
  done
}

# Interpolate {{PROJECT_NAME}} and {{TODAY}} in a file.
render() {
  local src="$1"
  local dst="$2"
  local name="$3"
  local type="$4"
  local today
  today=$(date +%Y-%m-%d)
  sed "s/{{PROJECT_NAME}}/$name/g; s/{{TODAY}}/$today/g; s/{{PROJECT_TYPE}}/$type/g" "$src" > "$dst"
}

# Copy a template file if it exists, otherwise skip.
cp_template() {
  local tpl="$1"
  local dst="$2"
  if [[ -f "$tpl" ]]; then
    render "$tpl" "$dst" "$PROJECT_NAME" "$PROJECT_TYPE"
    info "  created: $(basename "$dst")"
  fi
}

# ── Argument parsing ───────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)    usage; exit 0 ;;
    --type)
      PROJECT_TYPE="$2"; shift 2 ;;
    --type=*)
      PROJECT_TYPE="${1#*=}"; shift ;;
    --no-git)     NO_GIT=true; shift ;;
    --verbose)    VERBOSE=true; shift ;;
    -*)
      die "Unknown option: $1 (use --help)" ;;
    *)            break ;;
  esac
done

if [[ $# -lt 1 ]]; then
  usage
  die "project-name is required"
fi

PROJECT_NAME="${1//[^a-zA-Z0-9_-]/-}"   # sanitize to safe dirname
PROJECT_ROOT="$(pwd)/$PROJECT_NAME"

if [[ -d "$PROJECT_ROOT" ]]; then
  die "Directory already exists: $PROJECT_ROOT"
fi

# ── Validate type ─────────────────────────────────────────────────────────────

if [[ ! "$PROJECT_TYPE" =~ ^(coding|knowledge|ops|minimal)$ ]]; then
  die "--type must be one of: coding, knowledge, ops, minimal"
fi

# ── Create directory skeleton ──────────────────────────────────────────────────

info "Creating project '$PROJECT_NAME' (type: $PROJECT_TYPE)..."
mkdir -p "$PROJECT_ROOT"
mkdir -p "$PROJECT_ROOT/.pi/sessions"
mkdir -p "$PROJECT_ROOT/inbox"
mkdir -p "$PROJECT_ROOT/scratch"
mkdir -p "$PROJECT_ROOT/logs"

# ── Type-specific directories ─────────────────────────────────────────────────

case "$PROJECT_TYPE" in
  coding)
    mkdir -p "$PROJECT_ROOT/src"
    mkdir -p "$PROJECT_ROOT/tests"
    mkdir -p "$PROJECT_ROOT/docs"
    mkdir -p "$PROJECT_ROOT/kb/references"
    ;;
  knowledge)
    mkdir -p "$PROJECT_ROOT/kb/topics"
    mkdir -p "$PROJECT_ROOT/kb/references"
    mkdir -p "$PROJECT_ROOT/reviews"
    ;;
  ops)
    mkdir -p "$PROJECT_ROOT/reports"
    mkdir -p "$PROJECT_ROOT/checks"
    ;;
  minimal)
    # nothing extra
    ;;
esac

# ── Template files ────────────────────────────────────────────────────────────

# AGENTS.md
AGENTS_TPL="$TEMPLATE_DIR/AGENTS.md"
if [[ -f "$AGENTS_TPL" ]]; then
  render "$AGENTS_TPL" "$PROJECT_ROOT/AGENTS.md" "$PROJECT_NAME" "$PROJECT_TYPE"
  info "  created: AGENTS.md"
else
  cat > "$PROJECT_ROOT/AGENTS.md" <<EOF
# {{PROJECT_NAME}} — Agent Instructions

## Project Overview

- **Name:** {{PROJECT_NAME}}
- **Created:** {{TODAY}}
- **Type:** $PROJECT_TYPE

## Goals

> Describe what this project aims to achieve.

## Rules

- Prefer minimal, correct changes over broad refactors.
- Run tests after meaningful edits.
- Summarise what changed and why.
- Compact with a note preserving current task, failing tests, and next step.

## Browser Automation

- NEVER run Playwright or any browser directly.
- Use the playwright-safe skill when browser access is needed.

## Context Files

- **PLAN.md** — authoritative task list; read on every turn.
- **.pi/progress.md** — current state checkpoint.
- **.pi/fail_log.md** — failures only (optional, for loop work).
- **inbox/** — unprocessed inputs.
- **scratch/** — temp work, safe to delete.
EOF
  info "  created: AGENTS.md"
fi

# PLAN.md
PLAN_TPL="$TEMPLATE_DIR/PLAN.md"
if [[ -f "$PLAN_TPL" ]]; then
  render "$PLAN_TPL" "$PROJECT_ROOT/PLAN.md" "$PROJECT_NAME" "$PROJECT_TYPE"
  info "  created: PLAN.md"
else
  cat > "$PROJECT_ROOT/PLAN.md" <<EOF
# Plan: {{PROJECT_NAME}}

## Overview

> One-paragraph description of what this project delivers.

## Verification

List the commands that must pass for this project to be considered complete.

EOF
  case "$PROJECT_TYPE" in
    coding)
      cat >> "$PROJECT_ROOT/PLAN.md" <<'EOF'
```bash
# Example — replace with your actual verification
pnpm build && pnpm test
```
EOF
      ;;
    knowledge)
      cat >> "$PROJECT_ROOT/PLAN.md" <<'EOF'
```bash
# Example — replace with your actual verification
pnpm lint:kb
```
EOF
      ;;
    ops)
      cat >> "$PROJECT_ROOT/PLAN.md" <<'EOF'
```bash
# Example — replace with your actual verification
bash checks/run.sh
```
EOF
      ;;
  esac
  cat >> "$PROJECT_ROOT/PLAN.md" <<EOF

## Tasks

- [ ] **Task 1:** $(date +%Y-%m-%d) — placeholder

EOF
  info "  created: PLAN.md"
fi

# .pi/config.json
cat > "$PROJECT_ROOT/.pi/config.json" <<EOF
{
  "name": "$PROJECT_NAME",
  "type": "$PROJECT_TYPE",
  "created": "$(date +%Y-%m-%d)",
  "pi": {
    "provider": "openrouter",
    "defaultModel": "anthropic/claude-sonnet-4.6"
  }
}
EOF
info "  created: .pi/config.json"

# .pi/progress.md
cat > "$PROJECT_ROOT/.pi/progress.md" <<EOF
# Progress: $PROJECT_NAME

> Updated after each session or major milestone.

## Status

- **Overall:** Not started
- **Last updated:** {{TODAY}}

## Completed

-

## In Progress

-

## Blockers

-
EOF
info "  created: .pi/progress.md"

# .pi/fail_log.md
cat > "$PROJECT_ROOT/.pi/fail_log.md" <<EOF
# Fail Log: $PROJECT_NAME

> One entry per failure. Format: task, error, attempt count, resolution.

## Entries

EOF
info "  created: .pi/fail_log.md"

# Type-specific extras
case "$PROJECT_TYPE" in
  coding)
    cp_template "$TEMPLATE_DIR/README.md"      "$PROJECT_ROOT/README.md"
    cp_template "$TEMPLATE_DIR/.gitignore"     "$PROJECT_ROOT/.gitignore"
    ;;
  knowledge)
    cp_template "$TEMPLATE_DIR/README.md"     "$PROJECT_ROOT/README.md"
    ;;
esac

# README.md (generic fallback)
if [[ ! -f "$PROJECT_ROOT/README.md" ]]; then
  cat > "$PROJECT_ROOT/README.md" <<EOF
# {{PROJECT_NAME}}

> {{TODAY}} — $PROJECT_TYPE project scaffolded with pi.dev

## Quick start

\`\`\`bash
# Run the plan
pi -p "Read PLAN.md and complete all tasks."

# Or start the Ralph loop
bash scripts/run-ralph.sh
\`\`\`
EOF
  info "  created: README.md"
fi

# ── Git init ──────────────────────────────────────────────────────────────────

if ! $NO_GIT; then
  if command -v git &>/dev/null; then
    (cd "$PROJECT_ROOT" && git init -q)
    # Default .gitignore for a Pi-aware project
    cat > "$PROJECT_ROOT/.gitignore" <<EOF
node_modules/
.pi/sessions/
*.log
.env
scratch/
.DS_Store
EOF
    info "  created: .gitignore"
    info "  git: initialized"
  else
    warn "git not found — skipping git init"
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "✓ Project created at: $PROJECT_ROOT"
report_tree "$PROJECT_ROOT"
echo ""
echo "  Next steps:"
echo "    cd $PROJECT_NAME"
echo "    # Edit PLAN.md with your actual tasks"
echo "    pi -p 'Read PLAN.md and complete all tasks.'"
echo ""

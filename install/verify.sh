#!/usr/bin/env bash
# verify.sh — runs 7 checks. Prints PASS/FAIL for each.
set -euo pipefail

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -f "$HOME/.pi/agent/openrouter-env.sh" ] && source "$HOME/.pi/agent/openrouter-env.sh"

PASS=0
FAIL=0

check() {
  local name="$1"
  local result="$2"
  if [[ "$result" == "ok" ]]; then
    echo "PASS: $name"
    PASS=$((PASS+1))
  else
    echo "FAIL: $name — $result"
    FAIL=$((FAIL+1))
  fi
}

# 1. nvm loaded + Node >= 20
NODE_VER=$(node --version 2>/dev/null | cut -d. -f1 | tr -d 'v' || echo "0")
if (( NODE_VER >= 20 )); then
  check "nvm + Node >= 20 (got $(node --version))" "ok"
else
  check "nvm + Node >= 20" "Node not found or too old (got: $NODE_VER)"
fi

# 2. pi in PATH
if command -v pi &>/dev/null; then
  check "pi command in PATH ($(which pi))" "ok"
else
  check "pi in PATH" "pi not found — run: npm install -g @mariozechner/pi-coding-agent"
fi

# 3. Docker responsive
if docker info &>/dev/null 2>&1; then
  check "Docker daemon responsive" "ok"
else
  check "Docker daemon" "not running — start Docker Desktop"
fi

# 4. OPENROUTER_API_KEY set
if [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
  check "OPENROUTER_API_KEY is set" "ok"
else
  check "OPENROUTER_API_KEY" "not set — run: bash install/setup-openrouter.sh"
fi

# 5. OpenRouter key valid
if [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    "https://openrouter.ai/api/v1/auth/key" \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" 2>/dev/null || echo "000")
  if [[ "$HTTP_CODE" == "200" ]]; then
    check "OpenRouter key valid (HTTP 200)" "ok"
  else
    check "OpenRouter key valid" "HTTP $HTTP_CODE — check your key at https://openrouter.ai/keys"
  fi
else
  check "OpenRouter key valid" "skipped — key not set"
fi

# 6. Config files in ~/.pi/agent/
MISSING=""
for f in settings.json AGENTS.md models.json; do
  [[ ! -f "$HOME/.pi/agent/$f" ]] && MISSING="$MISSING $f"
done
if [[ -z "$MISSING" ]]; then
  check "Config files in ~/.pi/agent/" "ok"
else
  check "Config files in ~/.pi/agent/" "missing:$MISSING"
fi

# 7. Skill symlink intact
SKILL_MD="$HOME/.pi/agent/skills/playwright-safe/SKILL.md"
if [[ -f "$SKILL_MD" ]]; then
  check "playwright-safe skill symlink readable" "ok"
else
  check "playwright-safe skill symlink" "SKILL.md not found at $SKILL_MD"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]

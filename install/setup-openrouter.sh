#!/usr/bin/env bash
# setup-openrouter.sh — prompts for OpenRouter API key, writes env file.
# Never echoes the key. Called automatically by install-pi.sh.
set -euo pipefail

ENV_FILE="$HOME/.pi/agent/openrouter-env.sh"

echo ""
echo "=== OpenRouter API Key Setup ==="
echo "Get your key at: https://openrouter.ai/keys"
echo ""
read -rsp "Paste your OpenRouter API key (input hidden): " OPENROUTER_KEY
echo ""

if [[ -z "$OPENROUTER_KEY" ]]; then
  echo "ERROR: No key entered. Run this script again when you have your key."
  exit 1
fi

# Ensure directory exists (script may be called standalone, outside install-pi.sh)
mkdir -p "$(dirname "$ENV_FILE")"

cat > "$ENV_FILE" << EOF
export OPENROUTER_API_KEY="$OPENROUTER_KEY"
EOF
chmod 600 "$ENV_FILE"

# Add sourcing to .bashrc if not already there
if ! grep -q "openrouter-env.sh" "$HOME/.bashrc" 2>/dev/null; then
  echo "" >> "$HOME/.bashrc"
  echo "# Pi OpenRouter key" >> "$HOME/.bashrc"
  echo "source $ENV_FILE" >> "$HOME/.bashrc"
fi

# Load it now for the current session
source "$ENV_FILE"

echo "Key saved to $ENV_FILE (chmod 600)"
if grep -q "openrouter-env.sh" "$HOME/.bashrc" 2>/dev/null; then
  echo "Added to ~/.bashrc for future sessions."
fi

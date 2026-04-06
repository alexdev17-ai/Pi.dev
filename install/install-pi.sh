#!/usr/bin/env bash
# install-pi.sh — installs Pi coding agent in WSL2 with OpenRouter.
# Run from: /mnt/c/Users/HAAK/pi.dev/
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Pi.dev Install ==="
echo "Project: $PROJECT_DIR"
echo ""

# --- Step 1: Source nvm ---
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  echo "ERROR: nvm not found at $NVM_DIR. Install nvm first:"
  echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
  exit 1
fi
source "$NVM_DIR/nvm.sh"

NODE_VERSION=$(node --version)
NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1 | tr -d 'v')
if (( NODE_MAJOR < 20 )); then
  echo "ERROR: Node $NODE_VERSION is too old. Run: nvm install 22 && nvm use 22"
  exit 1
fi
echo "Node: $NODE_VERSION OK"

# --- Step 2: Install jq ---
if ! command -v jq &>/dev/null; then
  echo "Installing jq..."
  sudo apt-get install -y jq -qq
fi
echo "jq: $(jq --version) OK"

# --- Step 3: Install Pi ---
echo "Installing @mariozechner/pi-coding-agent..."
npm install -g @mariozechner/pi-coding-agent --quiet

PI_BIN=$(which pi 2>/dev/null || true)
if [[ -z "$PI_BIN" ]]; then
  # npm global bin may not be on PATH yet; add it
  NPM_PREFIX=$(npm config get prefix)
  export PATH="$NPM_PREFIX/bin:$PATH"
  if ! grep -q "npm config get prefix" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "# Pi / npm global bin" >> "$HOME/.bashrc"
    echo 'export PATH="$(npm config get prefix)/bin:$PATH"' >> "$HOME/.bashrc"
  fi
fi
echo "pi: $(which pi) OK"

# --- Step 4: Create ~/.pi/agent dirs ---
mkdir -p "$HOME/.pi/agent/"{prompts,skills,extensions}
echo "~/.pi/agent/ directories created."

# --- Step 5: Copy config ---
cp "$PROJECT_DIR/config/settings.json" "$HOME/.pi/agent/settings.json"
cp "$PROJECT_DIR/config/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
cp "$PROJECT_DIR/config/models.json" "$HOME/.pi/agent/models.json"
echo "Config files copied to ~/.pi/agent/"

# --- Step 6: Symlink playwright-safe skill ---
SKILL_TARGET="$PROJECT_DIR/skills/playwright-safe"
SKILL_LINK="$HOME/.pi/agent/skills/playwright-safe"
ln -sf "$SKILL_TARGET" "$SKILL_LINK"
echo "Skill symlinked: $SKILL_LINK -> $SKILL_TARGET"

# --- Step 7: Build Docker image ---
echo "Building pi-playwright-runner Docker image..."
docker build -t pi-playwright-runner "$PROJECT_DIR/skills/playwright-safe/runner/"
echo "Docker image built: pi-playwright-runner"

# --- Step 8: Add nvm to .bashrc if missing ---
if ! grep -q 'NVM_DIR' "$HOME/.bashrc"; then
  echo "" >> "$HOME/.bashrc"
  echo '# nvm' >> "$HOME/.bashrc"
  echo 'export NVM_DIR="$HOME/.nvm"' >> "$HOME/.bashrc"
  echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$HOME/.bashrc"
fi

# --- Step 9: OpenRouter key setup ---
bash "$PROJECT_DIR/install/setup-openrouter.sh"

echo ""
echo "=== Install complete ==="
echo "Run verify.sh to confirm everything is working:"
echo "  bash $PROJECT_DIR/install/verify.sh"
echo ""
echo "Then launch Pi:"
echo "  pi"

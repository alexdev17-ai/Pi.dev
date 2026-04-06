# Pi.dev Project Design Spec

**Date:** 2026-04-06
**Status:** Approved

---

## 1. Overview

Pi.dev is a project that:

1. Installs and configures the Pi coding agent (`@mariozechner/pi-coding-agent`) on Windows 11 via WSL2, using OpenRouter as the AI provider.
2. Ships a `playwright-safe` skill that provides Docker-backed browser automation with an injection guard layer, ensuring Pi never runs a browser on the host.

**Project location:** `C:\Users\HAAK\pi.dev\` (WSL2 access: `/mnt/c/Users/HAAK/pi.dev/`)

---

## 2. Environment

| Component | Version / Details |
|---|---|
| Windows 11 | Build 26200.8037 |
| WSL2 | Ubuntu 22.04.5 LTS |
| Node.js | v22.19.0 via nvm 0.39.7 (system Node v12 — must not be used) |
| npm | 10.9.3 |
| Docker Desktop | v28.2.2, WSL integration active |
| Docker Compose | v2.39.2 |
| Git | 2.34.1 (WSL) |
| Pi | Not yet installed |
| Disk | 930GB free on WSL root |
| RAM | 15GB |

**Critical constraint:** All install scripts must `source ~/.nvm/nvm.sh` before any `npm` or `node` commands, because the system Node (v12) is too old for Pi.

---

## 3. Project Structure

```
pi.dev/
├── README.md
├── .gitignore
├── install/
│   ├── install-pi.sh              # sources nvm, npm install -g, copies config, symlinks skills
│   ├── setup-openrouter.sh        # prompts for API key, writes env file
│   └── verify.sh                  # checks nvm, Node, Pi, Docker, OpenRouter connectivity
├── config/
│   ├── settings.json              # OpenRouter as default provider
│   ├── AGENTS.md                  # global agent instructions
│   └── models.json                # OpenRouter model map
├── skills/
│   └── playwright-safe/
│       ├── SKILL.md               # Pi skill manifest
│       ├── runner/
│       │   ├── Dockerfile         # extends mcr.microsoft.com/playwright
│       │   ├── playwright-runner.js
│       │   └── package.json
│       ├── guard/
│       │   ├── guard.sh           # regex injection scanner
│       │   └── patterns.txt       # one regex per line
│       └── bin/
│           └── playwright_safe_cli  # thin shim — Pi's only browser entry point
├── docs/
│   ├── pi-kb/                     # knowledge base (from starting info zips)
│   └── superpowers/specs/         # design specs (this file)
└── README.md
```

---

## 4. Install Flow

All steps run inside WSL2. No PowerShell bootstrap is needed — WSL reads `/mnt/c/Users/HAAK/pi.dev/` directly.

### 4.1 `install-pi.sh`

1. Source `~/.nvm/nvm.sh` and verify Node >= 20.
2. Install `jq` if not present (`sudo apt-get install -y jq`) — required by the guard layer.
3. `npm install -g @mariozechner/pi-coding-agent`.
4. Create directory structure: `~/.pi/agent/{prompts,skills,extensions}`.
5. Copy config files from `../config/` into `~/.pi/agent/`:
   - `settings.json`
   - `AGENTS.md`
   - `models.json`
6. Symlink skill: `ln -sf /mnt/c/Users/HAAK/pi.dev/skills/playwright-safe ~/.pi/agent/skills/playwright-safe`.
7. Build the Docker image: `docker build -t pi-playwright-runner /mnt/c/Users/HAAK/pi.dev/skills/playwright-safe/runner/`.
8. Add nvm sourcing to `~/.bashrc` if not already present, so `pi` works in new shells.
9. Call `setup-openrouter.sh` automatically.

### 4.2 `setup-openrouter.sh`

1. Prompt user to paste their OpenRouter API key (read -s, no echo).
2. Write `~/.pi/agent/openrouter-env.sh` with `export OPENROUTER_API_KEY="..."`.
3. `chmod 600 ~/.pi/agent/openrouter-env.sh`.
4. Add `source ~/.pi/agent/openrouter-env.sh` to `~/.bashrc` if not already present.

### 4.3 `verify.sh`

Checks (pass/fail for each):

1. nvm loaded and Node >= 20 active.
2. `pi` command found in PATH.
3. `docker` command available and Docker daemon responsive (`docker info`).
4. `OPENROUTER_API_KEY` set and non-empty.
5. OpenRouter key valid: `curl -s https://openrouter.ai/api/v1/auth/key -H "Authorization: Bearer $OPENROUTER_API_KEY"` returns 200.
6. Config files present in `~/.pi/agent/`.
7. Skill symlink intact: `~/.pi/agent/skills/playwright-safe/SKILL.md` readable.

---

## 5. Configuration

### 5.1 `settings.json`

```json
{
  "defaultProvider": "openrouter",
  "defaultModel": "anthropic/claude-sonnet-4-6",
  "defaultThinkingLevel": "medium"
}
```

### 5.2 `models.json`

Maps OpenRouter model IDs:

| Model | Use case |
|---|---|
| `anthropic/claude-sonnet-4-6` | Default — everyday coding and tasks |
| `anthropic/claude-opus-4-6` | Complex reasoning, architecture |
| `anthropic/claude-haiku-4-5` | Fast/cheap — compaction, formatting |
| `openai/gpt-4o` | Alternative non-Anthropic |
| `google/gemini-2.0-flash-001` | Bulk tasks |

### 5.3 `AGENTS.md`

Global standing instructions for Pi:

- Prefer minimal, correct changes over broad refactors.
- Run tests or lint after meaningful edits.
- Summarise what changed and why.
- Do not commit automatically unless asked.
- Use conventional commits.
- Compact with a note preserving current task, failing tests, and next step.

---

## 6. `playwright-safe` Skill

### 6.1 Purpose

Provide Pi with safe browser automation. Pi never has Playwright or Chromium installed. Every browser operation runs inside an ephemeral Docker container, and all output passes through an injection guard before Pi sees it.

### 6.2 Skill Manifest (`SKILL.md`)

Exposes one tool to Pi: `playwright_safe`, invoked via bash. Metadata tells Pi what operations are available and what the output looks like. Instructions tell Pi to never attempt browser automation through any other means.

### 6.3 Docker Runner

**Base image:** `mcr.microsoft.com/playwright:latest`

**`playwright-runner.js`** accepts CLI args:
- `--operation` (goto | click | extract_text | extract_links | screenshot | form_login)
- `--url`
- `--selectors` (JSON array)
- `--action-data` (JSON object, for form_login credentials etc.)

Returns structured JSON to stdout:

```json
{
  "status": "success",
  "messages": [],
  "data": {
    "url": "https://example.com",
    "title": "Example",
    "text": "page content...",
    "links": ["..."],
    "screenshot_path": "screenshots/1.png"
  }
}
```

**Container constraints:**
- `--rm` — ephemeral, no state persists.
- `-v "$PWD:/work"` — only the current work directory is mounted.
- `--init` — proper signal handling.
- No access to `~/.pi/`, host credentials, or other host paths.

### 6.4 Guard Layer (`guard.sh`)

**Input:** JSON from the Docker runner on stdin.

**Process:**
1. Parse JSON (jq).
2. Extract all string-valued fields.
3. Match each against `patterns.txt` regexes.
4. Compute cumulative `risk_score`:
   - Match in short field (< 200 chars): +0.80 per match.
   - Match in long field (>= 200 chars): +0.40 per match.
   - Capped at 1.0.
   - Rationale: a single unambiguous injection pattern in a short string (e.g. "ignore previous instructions") is sufficient evidence to block. The +0.80 value ensures one clear match = blocked without needing accumulation. Soft mentions in long-form text (+0.40) require two matches to block.
5. If `risk_score > 0.7`: set `status` to `"blocked"`, strip `text` field, replace with `"[content blocked — risk_score: X.X]"`.
6. Always append `risk_score` and `warnings` array to output.

**Pattern categories in `patterns.txt`:**

| Category | Examples |
|---|---|
| Instruction hijack | `ignore previous instructions`, `disregard.*above`, `you are an AI` |
| Command injection | `execute the following`, `run this.*command`, `eval\(`, `exec\(` |
| Secret exfiltration | `reveal.*secret`, `show.*api.key`, `print.*password` |
| Role manipulation | `you are now`, `act as`, `pretend to be`, `new instructions` |
| Hidden content | `display:\s*none`, `font-size:\s*0`, `visibility:\s*hidden` adjacent to instruction-like text |

**Future extension (phase 2):** Stub in `guard.sh` for an LLM critic — a cheap model that evaluates whether text contains agent-directed instructions vs. normal page content. No implementation in v1, just the hook point with a comment.

### 6.5 CLI Shim (`playwright_safe_cli`)

A bash script that:

1. Validates required args (`--operation`, `--url`).
2. Builds the `docker run` command:
   ```bash
   docker run --rm -v "$PWD:/work" -w /work --init \
     pi-playwright-runner \
     node /app/playwright-runner.js "$@"
   ```
3. Pipes container stdout through `guard.sh`.
4. Emits final guarded JSON to stdout for Pi.

**Pi's view:** It calls `bash playwright_safe_cli --operation goto --url "..."` and gets back sanitized JSON. It never knows about Docker or the guard.

### 6.6 Output Schema (what Pi receives)

```json
{
  "status": "success | error | blocked",
  "risk_score": 0.0,
  "messages": [],
  "warnings": [],
  "data": {
    "url": "string",
    "title": "string",
    "text": "string (or blocked placeholder)",
    "links": ["string"],
    "screenshot_path": "string | null"
  }
}
```

---

## 7. What Is NOT in Scope

- LLM critic for the guard (phase 2).
- MCP integration (Pi doesn't have built-in MCP).
- Persistent browser sessions across calls (each call is stateless).
- Authentication/cookie management across calls (each container is ephemeral).
- Pi extensions or TUI components.
- CI/CD or automated deployment.

---

## 8. Success Criteria

1. Running `verify.sh` in WSL2 passes all 7 checks.
2. `pi` launches and responds using OpenRouter.
3. `playwright_safe_cli --operation goto --url "https://example.com"` returns valid JSON with page title and text.
4. Injecting a known prompt-injection payload into a page returns `status: "blocked"` with `risk_score > 0.7`.
5. Pi can use the skill naturally: given an instruction like "go to example.com and get the page title", it calls the shim and processes the result.

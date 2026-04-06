# Pi Coding Agent — Complete Environment Guide

> Built from: this project's setup session (2026-04-06), the official Pi knowledge base, and the Gemini architectural deep-dive report.

---

## What Pi Is

Pi (`@mariozechner/pi-coding-agent`) is a **terminal-first coding agent kernel** by Mario Zechner. It is the opposite of monolithic tools like Claude Code or Cursor: instead of baking in features, it gives you composable primitives and lets you wire up exactly the agent you want.

**Mental model:** Pi is to agents what Vim is to editors — a small, fast, composable core you bend to your workflow.

**Official site:** https://shittycodingagent.ai / https://pi.dev

---

## This Project's Setup

| Item | Value |
|---|---|
| Local path | `C:\Users\HAAK\pi.dev\` |
| WSL2 path | `/mnt/c/Users/HAAK/pi.dev/` |
| GitHub | `alexdev17-ai/Pi.dev` |
| Pi install | `/home/haak/.nvm/versions/node/v22.19.0/bin/pi` |
| Config dir | `~/.pi/agent/` |
| Default model | `anthropic/claude-sonnet-4.6` (1M context via OpenRouter) |
| Provider | OpenRouter (`OPENROUTER_API_KEY` in `~/.pi/agent/openrouter-env.sh`) |
| Desktop shortcut | `Pi.lnk` → Windows Terminal → WSL2 → `launch-pi.sh` |

### Launch Pi

```bash
# From WSL2 terminal
source ~/.nvm/nvm.sh && source ~/.pi/agent/openrouter-env.sh && pi

# Or double-click the Pi desktop shortcut
```

---

## Core Architecture

Pi ships as four npm packages:

| Package | Responsibility |
|---|---|
| `@mariozechner/pi-ai` | Provider abstraction, model registry, streaming, tool calling, cross-provider context handoff |
| `@mariozechner/pi-agent-core` | Agent loop: run tools, stream events, queue/merge messages |
| `@mariozechner/pi-tui` | Terminal UI: custom differential renderer, panes, status bar, OSC8 links, image rendering |
| `@mariozechner/pi-coding-agent` | CLI: sessions, AGENTS.md loading, skills, extensions, config |

### The Four Tools

Pi exposes exactly four tools to the LLM — nothing more:

| Tool | What it does |
|---|---|
| `read` | Read files and binary metadata (with offset/limit) |
| `write` | Create/overwrite files and directories |
| `edit` | Apply in-place patches by textual match |
| `bash` | Execute shell commands synchronously |

Everything else — search, to-dos, MCP, dashboards, browser automation — is implemented as extensions or skills that call out to CLIs, scripts, or third-party tools.

### YOLO Security Model

Pi runs in **full-trust mode** by default:
- Full read/write access to the working directory (and typically your whole home dir)
- Unrestricted `bash` execution with your user privileges
- No built-in permission prompts

Guardrails must be added via sandboxing extensions (see Security section below).

---

## Execution Modes

| Mode | Command | Use case |
|---|---|---|
| Interactive TUI | `pi` | Daily coding, debugging, exploration |
| Print/one-shot | `pi -p "query"` | Scripts, CI pipelines, non-interactive queries |
| JSON output | `pi --mode json` | Structured event streams for automation |
| RPC | `pi --rpc` | JSON-RPC over stdin/stdout for non-Node integrations |
| SDK | `@mariozechner/pi-coding-agent` | Embed Pi runtime in your own applications |
| Max turns | `pi --max-turns 80 -p "..."` | Autonomous loops (Ralph-style) |

---

## Configuration Files

All config lives in `~/.pi/agent/`. This project's files are at `C:\Users\HAAK\pi.dev\config\` and symlinked/copied on install.

### `settings.json`

```json
{
  "defaultProvider": "openrouter",
  "defaultModel": "anthropic/claude-sonnet-4.6",
  "thinkingEnabled": true,
  "thinkingBudget": "medium"
}
```

### `models.json`

Pi's schema requires a `providers` object:

```json
{
  "providers": {
    "openrouter": {
      "baseUrl": "https://openrouter.ai/api/v1",
      "apiKey": "OPENROUTER_API_KEY",
      "api": "openai-completions",
      "models": [
        { "id": "anthropic/claude-sonnet-4.6", "name": "Claude Sonnet 4.6 1M" },
        { "id": "anthropic/claude-opus-4", "name": "Claude Opus 4" },
        { "id": "anthropic/claude-haiku-4-5", "name": "Claude Haiku 4.5" },
        { "id": "openai/gpt-4o", "name": "GPT-4o" },
        { "id": "google/gemini-2.0-flash-001", "name": "Gemini 2.0 Flash" }
      ]
    }
  }
}
```

### `AGENTS.md`

Global standing instructions Pi reads at startup. Stacks hierarchically with per-project `AGENTS.md` files found in subdirectories. This project's version adds a **Browser automation** section enforcing use of `playwright-safe` only.

---

## Context Engineering

Pi's context system has three layers:

### 1. AGENTS.md (hierarchical)

- Pi scans **upward** from the current working directory to the git root
- Concatenates every `AGENTS.md` found along the way
- Merges with `~/.pi/agent/AGENTS.md` (global)
- Use this for: project rules, build commands, coding conventions, tool restrictions

**Best practice:** Put broad rules at the repo root, narrow rules deep in subdirectories.

### 2. Skills

Skills are capability bundles with progressive disclosure:
- Lightweight metadata always available
- Full instructions loaded only when invoked
- Reference files streamed via `read` on demand

Skills live at `~/.pi/agent/skills/<skill-name>/SKILL.md`

**This project's skill:** `playwright-safe` — Docker-backed browser automation with injection guard.

### 3. Context Compaction

- Auto-triggers when approaching the model's context limit
- Manual: `/compact "note about current task and next step"`
- Custom compaction logic can be implemented via extensions
- **Critical for Ralph loops:** compaction notes let the agent reconstruct where it is after summarization

---

## Session Trees

Pi stores conversation history as a **tree**, not a flat log:

- `/tree` or double `Escape` — visualize the session graph
- Branch off any earlier point to experiment without losing context
- Rewind to before a destructive edit and try a different approach
- Sessions persist to disk — resume across terminal restarts

---

## Keyboard Shortcuts

| Action | Shortcut |
|---|---|
| Interrupt current response | `Escape` |
| Clear / new message | `Ctrl+C` |
| Exit | `Ctrl+C` twice or `Ctrl+D` |
| Delete to end of line | `Ctrl+K` |
| Cycle thinking level | `Shift+Tab` |
| Cycle models forward | `Ctrl+P` |
| Cycle models backward | `Shift+Ctrl+P` |
| Model selection overlay | `Ctrl+L` |
| Expand tools panel | `Ctrl+O` |
| Expand thinking panel | `Ctrl+T` |
| Open external editor | `Ctrl+G` |
| Run bash command | `!<command>` |
| Run bash (no context) | `!!<command>` |
| Queue follow-up message | `Alt+Enter` |
| Edit queued messages | `Alt+Up` |
| Paste image | `Ctrl+V` |
| Drop files | Drag onto terminal |
| Commands menu | `/` |

---

## Skills System

Skills are the Pi equivalent of Claude Code's MCP tools or slash commands — but simpler.

### SKILL.md format

```markdown
---
description: One-line description Pi uses to decide when to invoke this skill
---

# skill-name

What it does.

## Usage
\`\`\`bash
bash ~/.pi/agent/skills/skill-name/bin/entry-point --arg value
\`\`\`

## Rules
- Any Pi-facing constraints
```

### This project's skill: `playwright-safe`

Safe Docker-backed browser automation. Prevents Pi from running Playwright directly on the host.

```bash
# Full pipeline: bash shim → Docker container → injection guard → sanitized JSON
bash ~/.pi/agent/skills/playwright-safe/bin/playwright_safe_cli \
  --operation goto \
  --url "https://example.com"
```

Operations: `goto`, `click`, `extract_text`, `extract_links`, `screenshot`, `form_login`

Guard scoring: +0.80 per short-field match, +0.40 per long-field match. Threshold > 0.70 = blocked.

---

## Extensions System

Extensions are TypeScript modules that run inside the Pi process. They can:
- Register new slash commands
- Register new tools exposed to the LLM
- Add TUI components (panes, overlays, progress bars, widgets)
- Intercept pre/post-turn events to inject or filter context
- Implement security middleware

Extensions live at `~/.pi/agent/extensions/` or in project-local `.pi/extensions/`.

### Loading extensions

```bash
# Load one extension
pi --extension path/to/extension.ts

# Load multiple
pi --extension ext1.ts --extension ext2.ts

# Via justfile (recommended pattern)
just open pure-focus
```

### Reload without restarting

```
/reload
```

### Writing an extension (skeleton)

```typescript
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function(pi: ExtensionAPI) {
  // Register a slash command
  pi.registerCommand("/my-command", async (args) => {
    pi.ui.print("Hello from my extension!");
  });

  // Register a tool for the LLM
  pi.registerTool({
    name: "my_tool",
    description: "Does something useful",
    schema: { /* TypeBox schema */ },
    execute: async (args) => {
      return { result: "done" };
    }
  });

  // Hook into turn lifecycle
  pi.on("before-turn", (ctx) => {
    // Inject context before each LLM call
  });
}
```

---

## Notable Extensions from the Ecosystem

These exist in the community and can be installed. See `docs/pi-tasks.json` for the installation task list.

| Extension | Purpose |
|---|---|
| `pure-focus` | Strips footer and status line for distraction-free coding |
| `minimal` | Compact footer with model name + 10-block context meter |
| `cross-agent` | Scans for `.claude/`, `.gemini/`, `.codex/` dirs and imports their skills/commands into Pi |
| `purpose-gate` | Forces you to declare session intent before Pi responds |
| `tool-counter` | Footer showing model, tokens, cost, git branch, tool call counts |
| `tool-counter-widget` | Live above-editor widget for tool call telemetry |
| `till-done` | State machine that forces Pi to complete tasks fully before stopping |
| `pi-teams` | Multi-agent team orchestration with roles defined in `teams.yaml` |
| `agent-chain` | Sequential pipeline: output of agent N → input of agent N+1 |
| `pi-pi` | Meta-agent that builds and spawns other Pi agents |

---

## Multi-Agent Orchestration

### Ralph Loop in Pi

Pi can replace or enhance the Claude CLI Ralph loop:

```bash
pi \
  --provider openrouter \
  --model anthropic/claude-sonnet-4.6 \
  --thinking medium \
  --max-turns 80 \
  -p "Run the Ralph loop in PLAN.md. Work through tasks sequentially." \
  2>&1 | tee .pi/ralph/session-$(date +%Y%m%d-%H%M%S).log
```

State files: `PLAN.md`, `.pi/ralph/progress.md`, `.pi/ralph/fail_log.md`

### pi-teams (YAML-defined agent teams)

```yaml
# teams.yaml
teams:
  code-review:
    planner:
      model: anthropic/claude-sonnet-4.6
      role: "Decompose the task and assign subtasks"
    security:
      model: anthropic/claude-haiku-4-5
      role: "Scan for vulnerabilities rapidly"
    reviewer:
      model: anthropic/claude-sonnet-4.6
      role: "Ensure code quality and convention compliance"
```

### Justfile orchestration pattern

```makefile
set dotenv-load  # auto-injects .env keys

open EXTENSION:
    osascript -e 'tell app "Terminal" to do script "cd {{invocation_directory()}} && pi --extension extensions/{{EXTENSION}}.ts"'

open-team EXTENSIONS:
    # spawn isolated terminal per extension combination
```

---

## Security

### OS-Level Sandboxing (advanced)

Using `@anthropic-ai/sandbox-runtime`:
- **macOS:** `sandbox-exec`
- **Linux/WSL2:** `bubblewrap`

Configure in `.pi/sandbox.json`:

```json
{
  "network": {
    "allowed": ["github.com", "registry.npmjs.org", "openrouter.ai"]
  },
  "filesystem": {
    "readonly": ["/"],
    "readwrite": ["$PROJECT_DIR"],
    "deny": ["~/.ssh", "~/.pi/agent/openrouter-env.sh"]
  }
}
```

### This project's security layer

The `playwright-safe` skill adds a browser-specific security layer:
1. Pi never has Playwright installed — only the shim is accessible
2. Browser runs in ephemeral Docker container (no host access)
3. URL whitelist: only `http://` and `https://` allowed
4. Injection guard scans all output before Pi sees it
5. LLM critic hook stubbed for phase 2

---

## Provider Authentication

### OpenRouter (this project's setup)

```bash
export OPENROUTER_API_KEY="your-key"
# Or source the env file:
source ~/.pi/agent/openrouter-env.sh
```

Supports all Claude, GPT, Gemini models via one key.

### Direct Anthropic

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
pi /login anthropic
```

### OAuth (subscription-based, no per-token cost)

```bash
pi /login anthropic   # Claude Pro subscription
pi /login openai      # ChatGPT Plus
pi /login github      # GitHub Copilot
pi /login google      # Gemini CLI
```

---

## Install Reference

All install scripts are in `install/`. They target WSL2 Ubuntu 22.04.

```bash
# Full install from scratch
cd /mnt/c/Users/HAAK/pi.dev
bash install/install-pi.sh

# Just set/rotate OpenRouter key
bash install/setup-openrouter.sh

# Verify everything is working (7 checks)
bash install/verify.sh
```

Verify checks:
1. nvm + Node >= 20
2. `pi` in PATH
3. Docker daemon responsive
4. `OPENROUTER_API_KEY` set
5. OpenRouter key valid (HTTP 200)
6. Config files in `~/.pi/agent/`
7. `playwright-safe` skill symlink readable

---

## Project File Map

```
pi.dev/
├── install/
│   ├── install-pi.sh          Main installer
│   ├── setup-openrouter.sh    Key setup (interactive, hides input)
│   └── verify.sh              7-check health verification
├── config/
│   ├── settings.json          Provider + model defaults
│   ├── AGENTS.md              Global agent instructions
│   └── models.json            OpenRouter model map
├── skills/
│   └── playwright-safe/
│       ├── SKILL.md           Pi skill manifest
│       ├── bin/playwright_safe_cli   Entry shim
│       ├── guard/
│       │   ├── guard.sh       Injection scanner
│       │   └── patterns.txt   Regex patterns (5 categories)
│       └── runner/
│           ├── Dockerfile     mcr.microsoft.com/playwright base
│           ├── playwright-runner.js  6 browser operations
│           └── package.json
├── tests/
│   ├── test-guard.sh          5 guard tests (all pass)
│   └── test-runner.sh         Docker runner test (passes)
├── docs/
│   ├── pi-environment.md      This file
│   ├── pi-tasks.json          Enhancement task list
│   ├── pi-kb/                 7 official Pi knowledge base docs
│   └── superpowers/
│       ├── specs/             Design spec
│       └── plans/             Implementation plan
└── README.md
```

---

## Useful Commands Inside Pi

```
/help           Show all commands
/tree           Visualize session tree
/compact        Manual context compaction
/reload         Hot-reload extensions
/model          Switch model
/login          OAuth authentication
/files          Show files in context
/review         Code review of current changes
/todos          Show todo list
```

---

## References

- Official site: https://shittycodingagent.ai
- npm: https://www.npmjs.com/package/@mariozechner/pi-coding-agent
- Extensions docs: https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/docs/extensions.md
- SDK examples: https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/examples/sdk/README.md
- pi-vs-claude-code reference: https://github.com/disler/pi-vs-claude-code
- Knowledge base: `docs/pi-kb/` (7 reference files in this repo)

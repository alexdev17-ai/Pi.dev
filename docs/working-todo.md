# Working Todo — pi.dev Setup

> Active working list. Updated together as we go through the task list.

## Extensions to install

- [ ] **Task 6 — cross-agent extension** ⭐ high priority
  - Scans for `.claude/`, `.gemini/`, `.codex/` dirs and imports their skills/commands into Pi
  - Source: `extensions/cross-agent.ts` in `disler/pi-vs-claude-code`
  - Status: pending

- [ ] **Task 7 — till-done extension** ⭐ high priority
  - State machine forcing Pi to verify tasks before declaring done
  - Source: `extensions/till-done.ts` in `disler/pi-vs-claude-code`
  - Status: pending

- [ ] **Task 11 — OS-level sandboxing (bubblewrap) for WSL2**
  - Confines filesystem + network access; blocks ~/.ssh, .env, unauthorized outbound requests
  - Medium priority
  - ⚠️ Note: bubblewrap needs kernel features that may not work natively in WSL2 — investigate alternatives (gVisor, containers, etc.) first
  - Status: pending

- [ ] **Task 12 — agent-chain extension**
  - Pipelines: output of agent N → input of agent N+1 (e.g. research → summarize → format → publish)
  - Low priority
  - Source: npm or `badlogic/pi-mono`
  - Status: pending

- [ ] **Task 13 — Configure Ctrl+P model favorites**
  - Short rotation: Haiku (fast/explore) → Sonnet 4.6 (implement) → Opus 4.6 (architecture) → MiniMax M2.7 (alternative)
  - Currently 6 models in models.json — limit to curated shortlist
  - Status: pending

- [ ] **Task 4 — tool-counter extension**
  - Two-line footer: model + context meter + token/cost on line 1; CWD + git branch + tool call counts on line 2
  - Source: `extensions/tool-counter.ts` in `disler/pi-vs-claude-code`
  - Status: pending

## Investigate later

- Task 5 — purpose-gate extension (declare intent before Pi responds — low priority, friction for interactive use)

- Task 2 — pure-focus extension (distraction-free, no footer)
- Task 3 — minimal extension (compact footer, 2 elements)
- Any extended footer that fits this setup better than tool-counter
- **Task 8 — Justfile orchestration** — orchestrate Pi with extension combos (`just open tool-counter`, `just open-team`, `just open-ralph`). Medium priority. Requires `just` install + justfile creation.
- **Task 15 — LLM critic hook for playwright-safe guard (phase 2)** — pipe suspicious content to Haiku after regex scan; escalates risk_score if AI-directed instructions detected. Low priority; phase 2.
- **Task 16 — More playwright-safe test coverage** — missing tests for click, extract_text, extract_links, screenshot ops; guard boundary cases; full pipeline injection test. Medium priority.
- **Task 9 — pi-teams multi-agent extension** — YAML-defined agent teams with roles (planner, security, reviewer) each using different models. Low priority but interesting for multi-agent orchestration.
- **Task 10 — Pi Ralph loop** — file infrastructure for autonomous Ralph-style loops in Pi (`.pi/ralph/`, progress.md, fail_log.md, launcher). High priority. Review together with:
  - Task 7 (till-done) — both are autonomous loop mechanisms in Pi
  - User's existing Claude Code Ralph loop — compare all three, assess gaps and overlaps, decide what to implement or merge

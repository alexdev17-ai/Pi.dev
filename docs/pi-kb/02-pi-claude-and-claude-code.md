# Pi + Claude + Claude Code

> How to wire Pi to Anthropic/Claude, how it compares to Claude Code (CLI + desktop), and concrete patterns for using both together on coding and non‑coding tasks.

---

## 1. Anthropic Provider Setup in Pi

### 1.1 Authentication

Two main ways to authenticate Anthropic in Pi:

#### OAuth (Claude Pro/Max)

Best when you already pay for Claude Pro/Max and want Pi to share that quota.

```bash
pi auth anthropic   # starts browser OAuth flow
```

Pi stores the resulting token in its config; you don't need to manage API keys manually.

#### API Key

Best for headless/server use.

```bash
export ANTHROPIC_API_KEY=sk-ant-...
# Or persist in Pi config:
pi config set anthropic.apiKey sk-ant-...
```

### 1.2 Default Provider and Model

`~/.pi/settings.json` example:

```json
{
  "defaultProvider": "anthropic",
  "defaultModel": "claude-sonnet-4-6",
  "thinkingEnabled": true,
  "thinkingBudget": "medium"
}
```

Override per session:

```bash
pi --provider anthropic --model claude-opus-4-6 --thinking high
pi --provider anthropic --model claude-haiku-4-5 --thinking false
```

Mid‑session, use `/model` or `Ctrl+L` to switch model (or provider) without losing context.

---

## 2. Claude Models: Where They Fit in Pi

Given your usage (heavy Claude Code, Ralph loop, serious dev work), a practical mapping:

| Model | Use in Pi | Notes |
| --- | --- | --- |
| `claude-opus-4-6` | Architecture, gnarly bugs, security review | Expensive but best reasoning; use when stakes are high |
| `claude-sonnet-4-6` | Default coding model | Great quality/price; ideal for Ralph‑style loops |
| `claude-haiku-4-5` | Cheap helpers (search/compaction/formatting) | Use as a compaction or "janitor" model |

**Pattern:**
Run the main loop with Sonnet; offload compaction or bulk formatting to Haiku (via a custom compaction extension); temporarily escalate to Opus for tricky branches (e.g. architecture decisions or security reviews).

---

## 3. Pi vs Claude Code (Conceptual)

Claude Code has **three key strengths** over Pi:

1. Native MCP servers and rich tool catalog
2. Agent Teams: easily orchestrate multiple Claude agents with shared task lists
3. Scheduled tasks: first‑class support for cron‑like automation on Anthropic infra

Pi has **three key strengths** over Claude Code:

1. Minimal overhead and maximal context for your own files
2. Full programmability (extensions + skills + SDK) — you own the harness
3. Multi‑provider, cross‑session portability

Think of Claude Code as the **Anthropic‑centric cockpit**, and Pi as the **unopinionated kernel** you can bend into anything.

---

## 4. Everyday Coding Patterns: Pi + Claude Code Together

### 4.1 Pattern: Design in Claude Code, Execute in Pi

**When:** New feature or refactor touching multiple subsystems.

1. In Claude Code, open the repo and run:
   - `/plan` to get a structured plan
   - `/review` on existing code to understand constraints
   - `/doc` to generate/update high‑level docs
2. Once the plan is stable, extract it into `PLAN.md` (or your Ralph PRD format) in the repo.
3. Add `AGENTS.md` tuned for Pi, referencing `PLAN.md` and your project conventions.
4. Run Pi with Claude as provider to execute the plan via a Ralph loop.

**Benefit:** Use Claude Code's rich tooling/UX for planning, but Pi's continuous session and tree model for execution.

---

### 4.2 Pattern: Tight Feedback Loops

**Goal:** Keep using Claude Code for interactive exploration and Pi for heavier autonomous work without duplication.

- Keep **one canonical CLAUDE.md / AGENTS.md** file in the repo, written to be compatible with both tools.
- In Claude Code: that file drives `/plan`, `/schedule`, and interactive work.
- In Pi: that same file is loaded as AGENTS.md.

Canonically define:

- Coding style and conventions
- Testing and verification commands
- Project‑specific gotchas

This avoids two divergent "sources of truth" for your agent instructions.

---

### 4.3 Pattern: Agent Teams + Pi Sub‑Agents

Claude Code Agent Teams can orchestrate several tasks in parallel; Pi can act as **one of the teammates**.

Example:

- In Claude Code, define a team:
  - Lead agent: "Tech lead" (Claude Code)
  - Teammate A: "Backend implementer" (Claude Code)
  - Teammate B: "Pi specialist" (external)

Give the lead instructions like:

> When a task needs heavy refactoring, complex shell work, or multi‑provider experimentation, delegate it to the Pi specialist. They expose a CLI entrypoint `./pi-agent.sh` that takes a task description and returns a summary and patch.

On disk, implement `pi-agent.sh` roughly as:

```bash
#!/usr/bin/env bash
TASK_DESC="$1"

pi \
  --provider anthropic \
  --model claude-sonnet-4-6 \
  --thinking medium \
  -p "You are the Pi teammate in a larger agent team. Your job:
1. Read the repo and the PLAN.md/AGENTS.md instructions.
2. Implement the following task, then summarise what you did:

${TASK_DESC}

Return a human‑readable summary at the end."
```

Use the Agent SDK or simple file handshakes so the Claude Code lead picks up Pi's summary and patches.

---

## 5. Non‑Coding Workflows: Claude Code + Pi

You already use Claude for a lot more than code. Below are patterns that deliberately **reuse the same mental model** (files + tools + loops) for non‑coding tasks.

### 5.1 Research & Knowledge Capture

**Claude Code strengths:**
- Excellent at **rapid exploration** across large document sets or web search (when configured with MCP/search)
- Plan mode and Agent Skills are great for designing complex research workflows

**Pi strengths:**
- Great at **turning raw research into durable assets** — Markdown knowledge bases, indices, taxonomies
- Easier to script and run headless for overnight or periodic research jobs

**Pattern:**

1. Use Claude Code to:
   - Explore the topic, gather links, pull snippets into `notes/raw/` Markdown files
   - Use `/plan` to design a research agenda and data extraction protocol
2. Have Pi turn that raw material into:
   - `kb/overview.md` — high‑level summary
   - `kb/entities/*.md` — one file per key concept or entity
   - `kb/index.md` — a manually curated index with backlinks

Kickoff prompt for Pi:

```bash
pi -p "You are turning ./notes/raw/*.md into a long‑term knowledge base under ./kb.
1) Create kb/overview.md summarising the domain.
2) Create one file per major topic under kb/entities/.
3) Build kb/index.md that links everything together.
Use existing headings where possible, and preserve citations as plain text."
```

Do this once, then iterate with Pi or Claude Code as new material arrives.

---

### 5.2 Log / Incident Triage

Both tools can act as SRE assistants.

- Claude Code:
  - Great for **ad‑hoc incident debugging** while you're on call, especially with `/plan` and `/schedule` to set up recurring log checks.
- Pi:
  - Ideal for **local log spelunking** and custom, repo‑specific incident analysis.

Example: run Claude Code as a scheduled log monitor (per MindStudio pattern), then have Pi act as a **post‑mortem assistant** that:

- Reads `./logs/incidents/*.log`
- Groups incidents by service / root cause
- Generates `postmortems/YYYY-MM-DD-<incident>.md` with timelines and action items

Pi prompt:

```bash
pi -p "You are a postmortem drafting assistant.
1) Read ./logs/incidents/*.log.
2) Group incidents by service and root cause.
3) For each incident group, create a postmortem file under ./postmortems/ with:
   - Summary
   - Timeline of events
   - Root cause analysis
   - Customer impact
   - Short‑ and long‑term fixes.
4) Do NOT invent facts; rely only on logs and existing docs in ./docs/."
```

Claude Code can then review those postmortems, refine them, and push them to your wiki.

---

### 5.3 Personal & Team Productivity

Some concrete ideas:

- **Daily standup generator**
  - Claude Code scheduled task: every morning, summarise yesterday's commits/PRs/issues into `reports/daily/YYYY-MM-DD.md`.
  - Pi: takes that file, merges it with your personal notes, and drafts a Slack message or email.

- **Meeting note processor**
  - Record meeting → get transcript → save as `notes/raw/meeting-*.md`.
  - Pi: turns each into `notes/processed/` with decisions, action items, and owners.
  - Claude Code: uses Agent Teams to ensure follow‑up tasks are reflected in issue trackers.

- **Backlog grooming**
  - Claude Code: read tickets, cluster by theme, propose merges/splits.
  - Pi: restructures `BACKLOG.md` or `planning/*.md` files accordingly and ensures links to repos/docs are correct.

---

## 6. Using Claude Code Better *Because* You Have Pi

Having Pi in your toolbox should change how you use Claude Code:

1. **Think in terms of PRDs and plans as durable artefacts.**
   Claude Code is great for quickly iterating on plans; Pi is great for executing those plans repeatedly and tweaking them over time.

2. **Let Claude Code be the "front‑end" UX and Pi the "back‑end" worker.**
   Use Claude Code when you want rich feedback, diagrams, MCP integrations. Use Pi when the task is mostly file+shell operations and doesn't require visual output.

3. **Use Pi to automate your Claude Code workflows.**
   Example: a Pi script that, after a Ralph loop, opens Claude Code sessions pre‑loaded with specific diff, test results, and docs for review.

4. **Respect their different context economics.**
   - Claude Code: expensive system prompt, but strong built‑in behaviours and tooling.
   - Pi: cheap overhead, but you design the behaviours. For long workflows, the overhead difference matters.

5. **Lean on Pi for cross‑provider situations.**
   When you want GPT or Gemini in the mix (e.g. multilingual docs, special tools), Pi can orchestrate this and feed summarised results back into Claude Code sessions.

---

## 7. Quick Start Checklist for Your Setup

Given your existing Claude CLI + Ralph loop stack, a pragmatic adoption path:

1. **Install Pi globally:** `npm install -g @mariozechner/pi-coding-agent`.
2. **Run `pi auth anthropic`** to attach your Claude account.
3. **Create AGENTS.md** in a repo, mirroring relevant parts of your CLAUDE.md.
4. **Run Pi once interactively** in that repo and do a normal coding task (no Ralph loop yet).
5. **Add a small, 3‑task PLAN.md** and run a tiny Pi‑Ralph loop as a spike.
6. **Only after this feels stable**, consider porting your full Ralph loop to Pi (see Ralph document).

From here on, treat Pi as a parallel harness you can use **whenever Claude Code's context or orchestration model starts to feel like a constraint**.

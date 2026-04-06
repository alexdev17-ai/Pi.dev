# Pi vs Claude Code: Decision & Playbook

> A practical guide for deciding which tool to reach for in different situations, plus concrete hybrid patterns.

---

## 1. High‑Level Comparison

| Aspect | Pi (with Claude) | Claude Code (CLI / Desktop) |
| --- | --- | --- |
| Primary identity | Minimal, extensible coding agent kernel | Full‑fledged agentic coding product |
| Tool surface | `read`, `write`, `edit`, `bash` (4 tools) | Rich tool set incl. MCP, file viewers, plan mode |
| System prompt size | Very small | Large (product + tools + policies) |
| Session model | Tree, persistent | Linear, per session; `--continue` / `--resume` |
| Provider support | Multi‑provider | Anthropic only |
| Extensions | TypeScript extensions + skills, hot‑reload | Skills, MCP, plugins via Anthropic ecosystem |
| Security model | YOLO by default (full trust) | Permission prompts, safer defaults |
| Scheduling | Via your own cron/systemd/CI | Built‑in scheduled tasks (cloud) |
| Target user | Power user / agent builder | Broad dev audience |

---

## 2. Positives & Negatives Side by Side

### 2.1 Pi Positives

- **Control & Extensibility** — You own the harness and can customise everything from compaction to TUI.
- **Context Efficiency** — Minimal overhead leaves more tokens for your code/docs/logs.
- **Session Trees** — More natural fit for long, branching work and self‑debugging agents.
- **Multi‑Provider** — Not locked to Anthropic; can leverage GPT/Gemini, etc., when beneficial.
- **Terminal Integration** — Plays perfectly with tmux, shell scripts, your dotfiles.

### 2.2 Pi Negatives

- **Requires Engineering Effort** — You must design workflows, prompts, extensions.
- **YOLO Security** — No built‑in guardrails; you are responsible for containment.
- **Smaller Ecosystem** — Fewer off‑the‑shelf skills/plugins than Claude.
- **Less Friendly for Non‑Devs** — Terminal‑centric UX.

### 2.3 Claude Code Positives

- **Batteries‑Included** — Plan mode, Agent Teams, MCP, scheduling, web/desktop integration.
- **Great Defaults** — Strong UX, clear guardrails, good cost controls.
- **Deep Anthropic Integration** — Projects, CLAUDE.md, memory, cloud scheduling.
- **Richer Non‑Coding UX** — Easier to use for knowledge work, PRD creation, diagrams, etc.

### 2.4 Claude Code Negatives

- **Fixed Harness** — You can't easily change how it plans, compacts, or orchestrates beyond what Anthropic exposes.
- **Context Overhead** — Larger system prompt and tool configuration eat into available tokens for your data.
- **Anthropic‑Only** — No direct mixing of non‑Anthropic models.

---

## 3. Quick Decision Matrix (Coding Tasks)

### 3.1 Use Pi When…

- You are running **long multi‑step loops** (Ralph‑style) and are hitting context limits.
- You want to **branch and experiment** with different implementations without losing history.
- You want to **blend multiple providers** (Claude + something else).
- You need a **headless agent** that plugs into bespoke CI, automation, or your own orchestrators.

### 3.2 Use Claude Code When…

- You are doing **interactive coding** in a repo (exploring, debugging, writing tests) and appreciate the rich UX.
- You rely heavily on **MCP** (Playwright, browser, DB, etc.).
- You want **scheduled agents** on Anthropic infra with minimal setup.
- You are collaborating with less technical teammates who are comfortable with desktop/web, not Pi.

---

## 4. Quick Decision Matrix (Non‑Coding Tasks)

### 4.1 Use Pi When…

- You want to treat **non‑code artefacts as a repo**: notes, docs, CSV/JSON datasets.
- You need a **repeatable file‑based workflow** (e.g. daily report generation, log summarisation, knowledge base curation).
- You want a **background operator** (`rho` style) that runs on your machines.

### 4.2 Use Claude Code When…

- You are **designing workflows** interactively (e.g. prototyping a multi‑step process for documents).
- You want **plan mode** and diagrams while figuring out a process.
- You rely on **search/MCP** integrations (email, Notion, ticketing systems) exposed via Claude.

---

## 5. Hybrid Playbook for Everyday Work

A realistic split for a power user (like you):

- **Claude Code (~70–80%)** — interactive coding, ideation, planning, MCP‑heavy tasks.
- **Pi (~20–30%)** — long‑running loops, heavy automation, cross‑provider experiments, repo‑style non‑coding flows.

Below are concrete patterns.

### 5.1 Pattern: PRD‑First Development

1. Use Claude Code to brainstorm and refine a PRD:
   - Start from a rough idea, let Claude expand it.
   - Use plan mode to chunk work into phases and tasks.
2. Save the result as `PLAN.md` in the repo.
3. Use Pi with Claude as provider to **execute** the plan:
   - Either via an explicit Ralph loop
   - Or with a simpler "do the next N tasks" invocation
4. Optionally, return to Claude Code for review and code walkthroughs.

**Why this works well:** Claude Code is better at the *human‑in‑the‑loop design* stage; Pi is better at repeated execution of that design.

---

### 5.2 Pattern: Repo Hygiene & Maintenance

Use Claude Code for one‑off refactors or API design changes. Use Pi for regular repo chores:

- Updating dependencies on a schedule
- Enforcing consistent lint/format rules
- Periodic dead‑code detection and clean‑up
- Generating and updating changelogs

Example Pi task:

```bash
pi -p "You are maintaining this repo.
1) Update all dev dependencies within the allowed semver ranges.
2) Run pnpm lint && pnpm test.
3) If everything passes, update CHANGELOG.md with a summary of the changes and open a new entry.
4) Do not touch application code beyond what is required for passing tests."
```

Schedule this via cron/systemd on your dev machine or CI, while Claude Code remains your interactive tool for deeper refactors.

---

### 5.3 Pattern: Knowledge Base Dev‑Ops

You already maintain a lot of written artefacts; treat them as a repo for Pi:

- Claude Code: drafting and exploratory editing of docs.
- Pi: enforcing structure, consistency, and generating indices.

Pi tasks:

- Normalising frontmatter in Markdown files
- Ensuring all internal links resolve
- Generating tag or topic indices
- Splitting monolithic docs into smaller, linked units

Claude Code tasks:

- High‑level restructuring ("should this be one doc or three?")
- Integrating diagrams and graphs using MCP tools

---

### 5.4 Pattern: Personal Operator

Combine Pi (or `rho` built on Pi) with Claude Code:

- Pi (rho‑style): runs in the background, checks in daily, writes notes and summaries to a repo.
- Claude Code: you periodically open the repo and ask Claude to help you search, refactor, and act on those notes (e.g., turn them into tickets or projects).

Pi responsibilities:

- Daily summary of git activity
- Syncing calendar exports or time tracking logs into Markdown
- Maintaining a `TASKS.md` / `INBOX.md` with structured todos

Claude Code responsibilities:

- Turning tasks into tickets in whatever system you use via MCP
- Helping you plan sprints or weekly focus based on the backlog

---

## 6. Migration Strategy (Incremental)

If you want to bring Pi into your stack without destabilising what already works:

1. **Single Repo, Minimal Pi Use**
   Pick one repo, install Pi, and use it strictly for:
   - A small 2–3 task plan
   - A single non‑critical chore (e.g. tidy up docs)

2. **Shared Instructions**
   Create a shared `AGENTS.md` / `CLAUDE.md` that works for both tools.

3. **One Small Ralph Loop on Pi**
   Run a Pi Ralph loop on a mini plan in that repo.

4. **Observe & Compare**
   - Context usage
   - Failure modes
   - Fix‑ability when the agent gets stuck

5. **Scale Up**
   Only once happy, consider porting a larger plan or a real project loop.

This keeps your existing Claude CLI loop as the "known good" baseline while you probe Pi's edges.

---

## 7. Rule of Thumb

> If the work is highly interactive, involves many external tools, or benefits from Anthropic's scheduling and MCP, **start in Claude Code**.
>
> If the work is long‑running, primarily file+shell based, or you want to experiment with agent behaviours and providers, **start in Pi**.

You don't need to choose one permanently. The user‑beneficial mindset is **"and", not "or"**: Claude Code as your cockpit; Pi as your custom engine room.

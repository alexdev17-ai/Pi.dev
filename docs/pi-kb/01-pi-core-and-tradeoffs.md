# Pi Core, Philosophy, and Trade‑Offs

> A compact but opinionated reference for Pi as a minimal coding agent kernel — including architecture, strengths, weaknesses, and where it fits relative to Claude Code.

---

## 1. What Pi Is (In One Page)

Pi is a **terminal‑first coding agent kernel** with:

- Exactly **four tools** exposed to the LLM: `read`, `write`, `edit`, `bash`
- A **very short system prompt** (under 1k tokens) and minimal baked‑in behaviour
- A **session tree** model instead of a linear chat log
- A **TypeScript extension and skills system** for everything else
- First‑class **multi‑provider support** with mid‑session model switching

Pi is deliberately *not* a product with lots of features; it is a **harness** you extend until it behaves like your ideal agent. OpenClaw is essentially "Pi, wired up to the world".

**Mental model:** Pi is to agents what Vim/Neovim are to editors: a small, composable core that you bend to your workflow.

---

## 2. Architecture Overview

Pi ships as four packages:

| Package | Responsibility |
| --- | --- |
| `@mariozechner/pi-ai` | Provider abstraction, model registry, streaming, tool calling, cross‑provider context handoff, thinking traces |
| `@mariozechner/pi-agent-core` | Agent loop: run tools, stream events, queue / merge messages |
| `@mariozechner/pi-tui` | Terminal UI: panes, status bar, message stream, custom components |
| `@mariozechner/pi-coding-agent` | CLI: sessions, AGENTS.md loading, skills, extensions, config |

**Key point:** `pi-ai` is reusable outside Pi; you can embed the same orchestration in custom Node/TS agents.

---

## 3. Core Tool Surface

Pi exposes exactly four tools to the model:

| Tool | Description | Typical Uses |
| --- | --- | --- |
| `read` | Read files and binary metadata (with offset/limit) | Source files, logs, JSON, Markdown, PDFs |
| `write` | Create/overwrite files and directories | New source files, config, notes, generated docs |
| `edit` | Apply in‑place patches by textual match | Small edits, refactors, configuration tweaks |
| `bash` | Execute shell commands synchronously | Tests, linters, build, CLI calls, curl, git |

That is the *entire* tool API. Everything else (search, to‑dos, dashboards, MCP, etc.) is implemented as **extensions or skills** that call out to CLIs, scripts, or third‑party tools.

### YOLO by Default

Pi intentionally runs in **full‑trust mode**:

- Full read/write access to the working directory (and typically your whole home dir)
- Unrestricted `bash` execution with your user privileges
- No built‑in permission prompts for tools

If you need guardrails, the expectation is:

- Run Pi in a **container or VM** with constrained filesystem/network
- Or build your own permission layer via extensions (e.g. listeners that block certain commands)

---

## 4. Context Engineering Primitives

Pi uses *files and skills* as the primary context mechanisms.

### 4.1 Files

Pi loads context from the filesystem at startup:

- `AGENTS.md` — primary "standing orders" for the agent. Can be defined globally (`~/.pi/agent/AGENTS.md`), per‑directory, and per‑project; files stack hierarchically.
- `SYSTEM.md` — overrides or extends the built‑in system prompt for a project.
- Arbitrary **reference files** (e.g. `CONTRIBUTING.md`, `DOCS.md`, `STYLEGUIDE.md`) that Pi can `read` as needed.

The model learns that *important rules live in Markdown files*; it will re‑read them when needed instead of trying to memorise them.

### 4.2 Skills

Skills are capability bundles that follow a progressive‑disclosure pattern:

- Lightweight metadata is always available
- Instructions are loaded only when the skill is invoked
- Large reference content is held in files and streamed via `read` when explicitly requested

Skills are ideal for:

- Project‑specific workflows (e.g. "how to deploy this repo")
- Larger reference corpora (API docs, internal wikis)
- Complex tools composed of many CLI calls

### 4.3 Compaction

Pi supports automatic and manual context compaction:

- Auto‑compaction triggers when the session approaches the model's context limit
- Manual compaction: `/compact "note about current task"`
- Compaction behaviour is replaceable — custom extensions can implement topic‑aware, code‑aware, or file‑aware summarisation, optionally using a cheaper model

**Crucial for loops:** compaction notes let the agent *reconstruct where it is* even after aggressive summarisation.

---

## 5. Sessions as Trees (Why It Matters)

Most agents treat history as a linear log. Pi stores sessions as **trees**:

- Every time you branch off an earlier point, a new child branch is created
- `/tree` visualises the branching structure
- You can **rewind to any node** and continue from there

Practical benefits:

- Side‑quests: debug a broken tool or experiment with an alternate approach on a branch, then return to the main line
- Comparative experiments: e.g. two different implementations or refactors side by side
- Safe tool development: branch to prototype an extension, then merge back once it works

---

## 6. Extension System and Ecosystem

Pi's extension model is intentionally small but powerful:

- Extensions are TypeScript modules
- They can declare:
  - Slash commands (e.g. `/answer`, `/todos`, `/review`, `/files`, `/ralph`)
  - New tools exposed to the LLM
  - TUI components (panes, overlays, progress bars)
  - Pre/post‑turn hooks to inject or filter context
- State is persisted in `.pi/` and can be read/written by both agent and human

The ecosystem already includes:

- **Productivity:** `/answer`, `/review`, `/todos`, `/files`, `pi-agentic-compaction`, `pi-token-burden`
- **Infra & orchestration:** `pi-tramp` (remote over SSH/Docker), `pi-queue` (webhook runner), `pi-multi-pass` (multi‑sub account rotation)
- **Personal operators:** `rho` (always‑on background operator), Mercury (multi‑channel personal assistant), `pi-boomerang` (token‑efficient autonomous loops)
- **UI:** Glimpse + `pi-generative-ui` for native window dashboards

You can treat existing extensions as **reference implementations** and have Pi create modified versions tuned to your workflow.

---

## 7. Where Pi Shines (Positives)

**1. Maximal Context Efficiency**
Minimal system prompt and "no tools by default" means more of the context window remains available for your actual code, docs, and workflows.

**2. Session Trees and Continuity**
The tree model plus persistent sessions is a major win for long‑running work, agents that debug themselves, and multi‑branch experiments.

**3. Multi‑Provider, Mid‑Session Switching**
Use Claude for most work, switch to GPT/Gemini for a specific strength, or use Haiku‑class models for compaction and cheap tasks without losing conversation history.

**4. Extensibility and Ownership**
You can build exactly the agent you want, with your own rules, tools, and workflows. No waiting for vendor features, and no opaque behaviour you cannot inspect.

**5. Terminal‑Native UX**
Pi feels like a well‑written terminal tool: fast, low‑flicker, tiny memory footprint. It composes naturally with tmux, fzf, git, and your existing shell workflows.

**6. Great for Agent Builders**
If you are building your own orchestrators or products (like OpenClaw, Mercury, or custom internal agents), Pi is a strong foundation instead of reinventing an agent loop and context management.

---

## 8. Where Pi Is Weak (Negatives / Limitations)

**1. Not for Non‑Technical Users**
Pi assumes you're comfortable with terminals, Node, pnpm, and editing config/TypeScript. The default UX is closer to Neovim than to a polished consumer app.

**2. YOLO Security Model**
No built‑in permission prompts. If you are not comfortable with an agent that can `rm -rf` your repo or exfiltrate secrets, you must add your own guardrails (containers, VMs, or custom extensions).

**3. No Built‑In Plan Mode / To‑Dos / MCP**
If you rely heavily on Claude's plan mode, rich MCP ecosystem, or built‑in task tracking, you must re‑implement analogous patterns (files + extensions) yourself.

**4. Ecosystem Still Younger Than Claude Code**
As of 2026, Pi's ecosystem is growing but smaller than Claude Code's agent teams + MCP + skills ecosystem. You'll write more yourself.

**5. Requires You to Think in Workflows**
Pi gives you primitives, not an opinionated workflow. If you don't have a mental model for how you want work to flow (files, skills, loops), you can feel lost.

---

## 9. Typical Use Cases (Coding & Beyond)

Below is a non‑exhaustive list of the kinds of work Pi is particularly good at. Later documents go into more depth.

### 9.1 Coding / Dev Work

- Greenfield feature implementation from PRDs or tickets
- Large‑scale refactors with branches and selective merging
- Test creation/maintenance (including golden file regeneration)
- Repo hygiene: dependency updates, lint/format standardisation
- Code review sub‑agents that read the diff while the main agent stays focused

### 9.2 Operations & SRE

- Log triage via `bash` + `grep` + `jq`
- On‑call helpers: summarise recent incidents from journalctl and alert logs
- CI failure analysis: read build artifacts, propose fixes, patch pipelines
- Cluster/config audits: read Terraform/Helm/YAML files, suggest simplifications

### 9.3 Knowledge Work & Docs

Because Pi can `read` and `write` arbitrary files, it is a capable **general knowledge work agent** when pointed at a docs folder:

- Generate and maintain internal runbooks from scattered notes
- Restructure a docs tree (split/merge files, fix cross‑links)
- Turn meeting notes into structured RFCs, ADRs, or PRDs
- Build and maintain an internal "second brain" as Markdown in a repo

### 9.4 Personal / Non‑Coding Tasks

Via extensions like `rho` and Mercury and simple shell scripts, Pi can:

- Maintain a Markdown task inbox and daily scratchpad
- Triage email exports or customer support transcripts (when available via files/CLI)
- Prepare status reports by aggregating logs, commits, and notes
- Schedule and run check‑ins (e.g. "every morning, summarise yesterday's git log and open PRs into `reports/YYYY-MM-DD.md`")

These non‑coding flows are largely built on the same primitives as coding: `read`, `write`, `edit`, `bash`, plus well‑designed AGENTS.md and skills.

---

## 10. Pi vs Claude Code: High‑Level Positioning

At a high level:

- **Claude Code** is a **product**: strong defaults, polished UX, built‑in MCP, plan mode, and scheduled tasks.
- **Pi** is a **kernel**: small, rigid core; you do the orchestration.

A realistic stance for a power user:

> Use Claude Code for most interactive coding and for anything that benefits from MCP and Anthropic's infrastructure. Use Pi for custom, long‑running, or experimental workflows where you want more control than Claude gives you.

This document is the base layer; the other documents in this bundle apply it to Claude, Ralph loops, everyday workflows, and decision‑making.

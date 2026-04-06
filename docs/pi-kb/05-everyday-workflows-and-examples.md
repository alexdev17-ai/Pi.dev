# Everyday Workflows with Pi + Claude Code

> Concrete, copy‑pasteable patterns for using Pi alongside Claude Code in real daily work — both coding and non‑coding.

---

## 1. Coding‑Centric Workflows

### 1.1 PR‑Driven Development (Single Feature)

**Scenario:** You have a feature ticket and want to go from idea → PR with strong automation.

1. **Draft PRD in Claude Code**
   - Paste the ticket + relevant context.
   - Ask Claude to write a short PRD.
   - Prompt example:
     > "Draft a concise PRD for this feature using my CLAUDE.md style.
     > Include: goals, non‑goals, success criteria, and a 5–8 item implementation task list."

2. **Convert PRD to PLAN.md**
   - Ask Claude Code to output a `PLAN.md` suitable for both Claude and Pi.
   - Save it in repo.

3. **Execute with Pi**
   - Run Pi with `AGENTS.md` referencing `PLAN.md`.
   - Either:
     - Run a full Ralph loop until all tasks are done.
     - Or ask Pi to do *only* the first 2–3 tasks.

4. **Review with Claude Code**
   - Open the repo in Claude Code and run `/review` on the diff.
   - Ask it to comment on design, edge cases, and test coverage.

**Why:** Each tool does what it's best at: Claude Code for design and review; Pi for deterministic execution.

---

### 1.2 Multi‑Repo Change (Monorepo / Fleet of Services)

**Scenario:** You need to change a shared library and then update several services that depend on it.

1. Use Claude Code to understand the change surface:
   - Search for usages with its tools.
   - Have it produce a matrix like `service x change type`.

2. Create a `multi-repo-plan.md`:

   ```markdown
   # Multi‑Repo Plan: Update Auth Library

   ## Verification
   - `pnpm test` in each affected repo

   ## Repos and Tasks

   - [ ] repo-auth-lib: implement new token API
   - [ ] repo-service-A: use new token API
   - [ ] repo-service-B: use new token API
   - [ ] repo-service-C: update tests for new behaviour
   ```

3. Write a shell script that sequentially calls Pi in each repo:

   ```bash
   #!/usr/bin/env bash

   for repo in auth-lib service-A service-B service-C; do
     (cd "../${repo}" && \
       pi --provider anthropic --model claude-sonnet-4-6 --thinking low \
          -p "You are implementing the part of multi-repo-plan.md relevant to this repo.
Read ../multi-repo-plan.md and focus only on tasks mentioning ${repo}.
When done, run pnpm test and summarise your changes." )
   done
   ```

4. Use Claude Code to do a final pass across all repos for verification and release packaging.

---

### 1.3 Refactor Assistant

**Goal:** Use Pi for the *mechanical* refactor and Claude Code for higher‑level guidance.

1. In Claude Code, discuss the desired refactor: rename a module, extract an interface, change error‑handling strategy.
2. Ask it to output a `REFACTOR_PLAN.md` with precise steps.
3. In Pi, run:

   ```bash
   pi -p "Read REFACTOR_PLAN.md and implement it step by step.
After each major step, run the configured tests.
If tests fail, try to fix them up to three times.
If you get stuck, leave a detailed note in .pi/refactor-failures.md."
   ```

4. Once Pi is done, use Claude Code's `/review` and `/explain` features to audit the result.

---

## 2. Non‑Coding Workflows

### 2.1 Personal Knowledge Base (PKB)

**Goal:** Build and maintain a local Markdown knowledge base, powered by both tools.

1. **Capture with Claude Code**
   - Use Claude Code to talk through ideas, articles, and insights.
   - Ask it to output structured notes into `notes/inbox/*.md`.

2. **Organise with Pi**
   - Periodically run an organising pass with Pi:

     ```bash
     pi -p "You are maintaining my knowledge base.
1) Read notes/inbox/*.md.
2) Merge overlapping notes into kb/topics/*.md.
3) Update kb/index.md with links to new/updated topics.
4) Move processed files from notes/inbox/ to notes/processed/."
     ```

3. **Query with Claude Code**
   - Point Claude Code at the repo and ask questions like "What have I learned about Pi vs Claude Code trade‑offs this month?".

---

### 2.2 Weekly Review & Planning

**Goal:** Automate a GTD‑style weekly review.

1. **Inputs**: calendar exports, `TASKS.md`, git logs, meeting notes.

2. **Pi Weekly Review Script**:

   ```bash
   pi -p "You are doing my weekly review.
1) Read TASKS.md, notes/meeting-*.md for this week, and git log (via `git log --since='7 days ago'`).
2) Summarise what I did this week into weekly/summary-YYYY-MM-DD.md.
3) Identify 5–10 open loops and write them as actionable tasks in TASKS.md.
4) Suggest 3 focus areas for next week and append them under a 'Focus' section in TASKS.md."
   ```

3. **Claude Code Planning**:
   - Open the repo in Claude Code.
   - Use it to:
     - Turn the focus areas into a concrete plan with time estimates.
     - Generate a simple calendar of deep‑work blocks.

---

### 2.3 Document Production Pipelines

**Scenario:** You write a lot of docs (design docs, RFCs, user guides) and want a pipeline that enforces structure.

1. **Claude Code for Drafting**
   - Draft doc interactively.
   - Get diagrams and outlines.

2. **Pi for Normalisation**
   - A Pi pass that:
     - Ensures consistent frontmatter (`title`, `status`, `owner`, `reviewers`).
     - Verifies all headings follow a house style.
     - Checks links and backreferences.

   ```bash
   pi -p "Normalise all docs in docs/*.md:
1) Enforce YAML frontmatter with title/status/owner.
2) Ensure section order: Overview, Context, Design, Trade-offs, Risks, Alternatives.
3) Check that every doc is linked from docs/index.md; if not, add it.
4) Produce docs/lint-report.md summarising any issues you had to fix."
   ```

3. **Claude Code for Review**
   - Run `/review` over the changed docs.
   - Ask it to flag unclear sections, missing edge cases, or contradictory statements.

---

## 3. Automation & Scheduling Patterns

### 3.1 Claude Code Scheduled Agents + Pi

- Use Claude Code's `/schedule` feature to run high‑level checks on a schedule.
- Use Pi as the **second stage** that takes outputs and performs deeper, repo‑level work.

Example:

1. Claude Code runs nightly, producing `reports/ci-failures-YYYY-MM-DD.md` summarising CI flakes.
2. Pi runs in the morning:

   ```bash
   pi -p "Read reports/ci-failures-*.md from the last 7 days.
Group failures by test suite and probable root cause.
Propose a remediation plan in docs/ci-stabilisation.md and open TODO items in TODO.md."
   ```

### 3.2 Pi as a Scheduled Operator (No Cloud)

If you prefer everything local:

- Use cron/systemd on your machine to run Pi scripts at intervals.
- Still use Claude Code interactively when you sit down at the keyboard.

---

## 4. Examples of Claude Code Improvements Enabled by Pi

1. **Better Plans** — Because Pi executes PLAN.md precisely, you can iterate on planning quality in Claude Code and immediately see execution consequences.
2. **Feedback Loop** — Pi can write execution feedback back into files (e.g. which tasks were underestimated), which Claude Code can use to update planning heuristics.
3. **Tool Hardening** — Use Pi to build, test, and refine custom CLI tools or small services that Claude Code then uses via MCP.
4. **Sandboxed Experiments** — Use Pi in a throwaway container to test risky operations; once safe, port them to Claude Code workflows.

---

## 5. How to Transfer These Patterns to Other LLMs

These documents are written to be **LLM‑agnostic**:

- They rely on **files, not proprietary features**.
- They assume only basic capabilities: read/write files, run shell commands, follow Markdown instructions.

To port to another LLM or orchestrator:

1. Store these docs as part of your **agent system context** or **skills**.
2. Ensure the agent has:
   - File read/write
   - Shell execution (or equivalent APIs)
   - Stable working directory
3. Replace references to `pi` and `Claude Code` with the equivalent CLI/SDK calls of that system.

Because the core patterns are tool‑agnostic (PRD → plan → loop; files as state; verification commands; compaction via summary notes), they transfer well to any agent framework.

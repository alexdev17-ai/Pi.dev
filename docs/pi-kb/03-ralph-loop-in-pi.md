# Ralph Loop in Pi (Advanced)

> How to model a Ralph‑style autonomous loop inside Pi, where you already have a sophisticated Claude CLI loop with verification and fail logs.

This document assumes you:

- Already run a Ralph loop in Claude CLI
- Use a PRD/PLAN file, verification commands, and structured fail logs
- Want to know whether Pi can improve the loop or handle certain classes of loop better

---

## 1. Concept Recap: Classic Ralph (Claude CLI)

In the original Ralph pattern:

- A **bash loop** spawns a new Claude process for each iteration
- Each process:
  - Reads the PRD (JSON or Markdown) and a progress file
  - Implements the next task
  - Runs verification commands
  - Logs failure or marks success
- State is carried across iterations only via files
- Each iteration is stateless from the LLM perspective

Your current loop extends this with:

- Verification & fail logs per iteration
- Multiple attempts per task before declaring a failure
- More nuanced logging and control logic

This is a great design for:

- **Robustness** — if Claude crashes, a new process starts clean
- **Reproducibility** — each iteration has a self‑contained transcript
- **Easy migration** — works with any tool that can be called as a CLI

But it has costs:

- No continuous in‑session learning about past attempts
- Context must be reconstructed from files every iteration
- Workarounds for context exhaustion are limited

Pi can change that trade‑off.

---

## 2. What Pi Changes for Ralph

### 2.1 Continuous Session

Instead of spawning a fresh process each iteration, Pi can run a **single long‑lived session** with `--max-turns N`.

Benefits:

- The agent remembers previous attempts, patterns, and decisions across iterations
- Fix attempts can be contextual ("last time we tried X and it failed because Y")
- You can steer the loop mid‑run without killing it (message queuing)

### 2.2 Session Tree

Each of the following can happen on its own branch:

- Infrastructure fix (e.g. flaky test harness)
- Alternate implementation attempt for a task
- Tool debugging (fixing a helper script)

You can:

- Branch off from before the failing attempt
- Experiment in a side branch
- Return to the main branch and continue the loop

### 2.3 Compaction with Notes

Pi's compaction allows you to annotate compaction with a note like:

> "Ralph: finished tasks [1,2,3], currently on task 4 (payments), known failing test: `tests/payments.test.ts` – intermittent timeouts."

This helps the agent reconstruct its context after aggressive summarisation, mitigating the **context exhaustion mid‑loop** pain point.

---

## 3. Minimal Pi‑Ralph Loop Design (Preserving Your Structure)

Instead of radical change, the goal is **to preserve your current structure, but move it inside Pi.**

### 3.1 PLAN and Logs

You can reuse your existing PRD/PLAN and logs with minimal changes:

- `PLAN.md` or `prd.json` — the authoritative task list and instructions
- `.pi/ralph/progress.md` — per‑iteration summaries
- `.pi/ralph/fail_log.md` — detailed failure records

The earlier starter templates remain valid — you only need to map them to your existing fields.

Where you now have a fail log with structured data, just ensure your Pi instructions tell the agent to log the same fields.

### 3.2 Loop Logic in AGENTS.md

Put the *loop protocol* (start each iteration, verify, commit, log, compact, stop conditions) into `AGENTS.md`. Pi will treat it as standing orders.

A compact version (you can tune to your current behaviour):

```markdown
## Ralph Loop Protocol (Pi)

At the start of each turn:
1. Read PLAN.md and identify the highest‑priority `Status: pending` task.
2. Read .pi/ralph/progress.md and .pi/ralph/fail_log.md.
3. Announce which task you are working on and your plan.

Implementation:
- Change only what is necessary to complete the current task.
- Prefer incremental commits over huge refactors unless the task requires it.

Verification:
- Run each verification command in PLAN.md.
- If all pass, commit and mark the task as passed.
- If any fail, attempt up to 3 targeted fixes.
- If still failing, log a detailed failure record and mark the task as failed.

Context management:
- After every 3 iterations, if context usage is high, run `/compact` with a note summarising completed tasks, current task, and known failures.

Termination:
- Stop when all tasks are passed or failed, or when you hit the configured iteration limit.
```

### 3.3 Execution Scripts

For small test runs, you can use a one‑shot `pi -p` invocation. For a real loop, create a small shell wrapper like:

```bash
#!/usr/bin/env bash

pi \
  --provider anthropic \
  --model claude-sonnet-4-6 \
  --thinking medium \
  --max-turns 80 \
  -p "You are running the Ralph loop described in AGENTS.md.
Read PLAN.md and .pi/ralph/progress.md, then begin.
Work through tasks sequentially according to the protocol." \
  2>&1 | tee .pi/ralph/session-$(date +%Y%m%d-%H%M%S).log
```

This gives you both:

- Pi's continuous session and tree model
- A standard log file per loop run

---

## 4. Pros & Cons: Pi Ralph vs Claude CLI Ralph

### 4.1 Pros of Pi‑Ralph

- **Continuous context** — the agent remembers patterns and pitfalls across tasks
- **Session tree** — safer experimentation and tool fixing
- **Mid‑loop steering** — queue steering messages without restarting the loop
- **Multi‑provider fallback** — if Claude rate‑limits, you can temporarily switch provider
- **Custom compaction** — better control over what is preserved vs summarised

### 4.2 Cons / Risks

- **Less isolation per iteration** — a bug in one iteration could bias later decisions more strongly than in a stateless model
- **More complex failure modes** — if the Pi session truly corrupts its internal plan, a simple "start fresh" behaviour is not automatic; you need to detect and restart intentionally
- **Higher surface area** — with continuous sessions and branches, debugging "what exactly happened?" can be more involved than inspecting one Claude transcript per iteration

Realistically, the Pi loop is a **higher‑power tool** that requires slightly more operational discipline:

- You'll want good logging, branch naming, and notes
- You should preserve your existing file‑based logs as the primary audit trail

If you do that, you get the benefits without losing your current robustness.

---

## 5. When Pi Should *Not* Replace Your Ralph Loop

Even with Pi available, your existing Claude CLI loop remains preferable when:

- You want **strong isolation per iteration** (e.g. for regulated envs or strict auditing) and are happy with file‑based state only
- You run many **short loops** where context rarely becomes a problem
- You value the ability to trivially rerun a single iteration in a fresh Claude process with no hidden session‑level state

In other words: if your current loop is reliable and context exhaustion is rare, Pi is an optimisation, not a necessity.

---

## 6. When Pi Is Clearly Better for Loop‑Style Work

Pi becomes clearly superior when at least one of these is true:

1. **Context exhaustion is common.**
   Long PRDs + many tasks + lots of code touched per iteration.

2. **Tasks are strongly interdependent.**
   Later tasks depend on nuanced understanding of how earlier ones were implemented.

3. **You want multi‑model or multi‑provider loops.**
   E.g. Haiku for compaction + Sonnet for implementation + GPT for natural‑language docs.

4. **You want self‑debugging agents.**
   The agent should be able to branch off, fix its own helper tools, and return.

5. **You want to embed the loop inside other systems.**
   e.g. A higher‑level orchestrator that uses Pi via RPC/SDK as a building block.

---

## 7. Example: Small Loop Optimised for Pi

For a 3–5‑task mini project (good Pi testing ground):

- Use a very small `PLAN.md` with checkboxes and a single verification command.
- Run Pi with Sonnet and moderate thinking.

Example PLAN:

```markdown
# Plan: Improve Logging

## Branch
feature/improve-logging

## Verification
- `pnpm test:logging`

## Tasks

- [ ] Add structured logging to auth service
- [ ] Add request IDs to all HTTP responses
- [ ] Document log fields in docs/logging.md
```

Kickoff prompt:

```bash
pi -p "Run the Ralph loop defined in PLAN.md to complete all tasks.
After each task, run the verification command and log progress to .pi/ralph/progress.md.
Stop when all tasks are completed or verification fails three times for a task."
```

This lets you evaluate Pi's loop behaviour without risking a big production feature.

---

## 8. Using Pi Ralph for Non‑Coding Loops

The same pattern works for **non‑coding** iterative work:

- Content production (e.g. multi‑chapter docs, blog series)
- Data curation (e.g. cleaning and normalising CSV/JSON files)
- Migration scripts (e.g. applying transformations to many small repos or services)

Example non‑coding PLAN:

```markdown
# Plan: Curate Internal AI KB

## Verification
- `pnpm test:lint-kb`   # custom script that checks link integrity and frontmatter

## Tasks

- [ ] Consolidate overlapping articles about "prompt engineering" into one canonical doc
- [ ] Normalise frontmatter fields across all kb/*.md files
- [ ] Build a tag index page at kb/tags.md
```

Run the same Pi loop; only the file types and verification commands change.

This is where Pi's uniform tool set (`read`, `write`, `edit`, `bash`) shines: **the loop logic is identical whether you are writing code, refactoring docs, or transforming data**.

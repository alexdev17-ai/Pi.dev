# {{PROJECT_NAME}} — Agent Instructions

## Project Overview

- **Name:** {{PROJECT_NAME}}
- **Created:** {{TODAY}}
- **Type:** {{PROJECT_TYPE}}

## Goals

> Describe what this project aims to achieve.

## Rules

- Prefer minimal, correct changes over broad refactors.
- Run tests after meaningful edits.
- Summarise what changed and why.
- Compact with a note preserving current task, failing tests, and next step.

## Browser Automation

- NEVER run Playwright or any browser directly.
- Use the playwright-safe skill when browser access is needed.

## Context Files

- **PLAN.md** — authoritative task list; read on every turn.
- **.pi/progress.md** — current state checkpoint.
- **.pi/fail_log.md** — failures only (optional, for loop work).
- **inbox/** — unprocessed inputs.
- **scratch/** — temp work, safe to delete.

## Verification

Run verification commands after each task. Do not mark a task complete unless verification passes.

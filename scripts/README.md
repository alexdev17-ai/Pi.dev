# Scripts

## `new-project.sh`

Scaffolds a new Pi-aware project.

```bash
bash scripts/new-project.sh <project-name> [options]

Options:
  --type coding|knowledge|ops|minimal   Project type (default: coding)
  --no-git                              Skip git init
  --verbose                             Print created files
```

### Project types

| Type | Extra directories |
|---|---|
| `coding` | `src/`, `tests/`, `docs/`, `kb/references/` |
| `knowledge` | `kb/topics/`, `kb/references/`, `reviews/` |
| `ops` | `reports/`, `checks/` |
| `minimal` | none |

### Output

Every project gets:
- `AGENTS.md` — project-specific standing orders
- `PLAN.md` — task list template
- `.pi/config.json` — Pi project metadata
- `.pi/progress.md` — checkpoint tracker
- `.pi/fail_log.md` — failure log
- `inbox/` — unprocessed inputs
- `scratch/` — temp work
- `logs/` — script/CI output
- `.gitignore`
- `README.md`

# Cross-Agent Importer (Claude Code Bridge) Plan

## Objective
A manual, selective skill to bridge configurations, project instructions, and session memory from **Claude Code** into **Pi's ecosystem** and the **Obsidian Vault**.

## Target Locations
- **Pi Core (Agent Rules):** `~/.pi/agent/AGENTS.md`
- **Pi Core (Skills):** `~/.pi/agent/skills/`
- **Project KB:** `/mnt/c/Users/HAAK/pi.dev/docs/pi-kb/`
- **Obsidian Vault Base:** `/mnt/c/Users/HAAK/Documents/Obsidian Vault/Pi.dev Base.base`

## Trigger Action
Ask Pi to: "sync with claude code", "import claude memory", "check claude code configs", or "bridge claude".

## Phases
1. **Scan & Assess:** Searches `CLAUDE.md`, `~/.claude.json`, `~/.claude/plugins/blocklist.json`, and recent `~/.claude/projects/*.jsonl` files.
2. **Report & Propose:** Presents a categorized report (Project Rules, Tools/Plugins, Recent Context/Memory). Stops and asks the user where to route each finding.
3. **Execute Selection:** Upon user confirmation, uses `edit` or `write` to transfer selected content into Pi's configurations, the `pi-kb/` directory, or Obsidian. Creates new `SKILL.md` files for ported tools.

*Note: Skill has been saved to `~/.pi/agent/skills/claude-code-bridge/SKILL.md`.*

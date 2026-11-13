# Claude Code Instructions

## Repository Overview

This is a Claude Code plugin marketplace. It hosts plugins that extend Claude Code with custom skills, distributed via the marketplace.

## Structure

```
plugins/<plugin-name>/
  .claude-plugin/plugin.json   # Plugin manifest (name, version, description, author)
  skills/<skill-name>/SKILL.md # Skill definition
  CHANGELOG.md                 # Auto-generated on release
.claude-plugin/marketplace.json # Marketplace manifest
.github/
  scripts/                     # Release and detection scripts
  workflows/                   # CI: validate on PR, release on merge to main
```

## Modifying Plugin Components

When adding, removing, or renaming any plugin component (skills, agents, commands, hooks):

1. Make the change under the relevant plugin directory
2. **Always update `README.md`** — the Available Plugins table must stay in sync with the current state of each plugin.

## Adding a New Plugin

1. Create `plugins/<name>/.claude-plugin/plugin.json` with `name`, `version`, `description`, `author`
2. Add skills under `plugins/<name>/skills/<skill-name>/SKILL.md`
3. Add the plugin entry to `.claude-plugin/marketplace.json`
4. Add a row to the Available Plugins table in `README.md`

## Versioning

**Always use Conventional Commits**, scoped to the plugin name (e.g. `feat(product): ...`, `fix(maintenance): ...`). The changelog and plugin versioning are driven entirely by commit messages — non-conventional commits will break the release automation.

For breaking changes, suffix with `!` (e.g. `feat(<plugin>)!: ...`, `fix(<plugin>)!: ...`).


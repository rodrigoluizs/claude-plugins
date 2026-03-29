# Claude Code Plugin Marketplace

Claude Code plugin marketplace.

## Installing the marketplace

In Claude Code, run:

```
/plugin marketplace add rodrigoluizs/claude-plugins
```

You will be prompted to install available plugins. Accept to install them all, or choose individually.

## Installing a specific plugin

After adding the marketplace:

```
/plugin install product
/plugin install maintenance
```

## Updating plugins

To get the latest versions of all installed plugins:

```
/plugin marketplace update
```

## Available plugins

| Plugin | Skills | Description |
|--------|--------|-------------|
| `product` | `create-prd` | Product management tools for feature definition and planning |
| `maintenance` | `dep-review` | Tools for routine repository maintenance and housekeeping |

## Adding a new plugin

1. Create a directory under `plugins/<your-plugin-name>/`
2. Add `.claude-plugin/plugin.json` with at minimum:
   ```json
   {
     "name": "your-plugin-name",
     "version": "1.0.0",
     "description": "What it does",
     "author": { "name": "Your Name", "email": "you@example.com" }
   }
   ```
3. Add your skills under `plugins/<your-plugin-name>/skills/<skill-name>/SKILL.md`
4. Add the plugin entry to `.claude-plugin/marketplace.json`
5. Open a PR — on merge to `main`, the release workflow auto-tags and versions it

## Versioning

Each plugin is versioned independently using tags in the format `<plugin>/vX.Y.Z` (e.g. `product/v1.2.0`).

Version bumps are determined automatically from [Conventional Commits](https://www.conventionalcommits.org/):

| Commit prefix | Version bump |
|---------------|-------------|
| `fix:` | patch (1.0.0 → 1.0.1) |
| `feat:` | minor (1.0.0 → 1.1.0) |
| `feat!:` or `BREAKING CHANGE` | major (1.0.0 → 2.0.0) |

## Changelogs

Each plugin has a `CHANGELOG.md` automatically updated on every release.
